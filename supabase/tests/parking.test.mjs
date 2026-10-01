import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {PGlite} from '@electric-sql/pglite';

const db = new PGlite();
const user1 = '00000000-0000-0000-0000-000000000001';
const user2 = '00000000-0000-0000-0000-000000000002';
await db.exec(`
  create role anon; create role authenticated; create role service_role bypassrls;
  create schema auth;
  create table auth.users(id uuid primary key);
  create function auth.uid() returns uuid language sql stable as $$
    select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid
  $$;
  grant usage on schema auth to authenticated,service_role;
  grant execute on function auth.uid() to authenticated,service_role;
  create publication supabase_realtime;
`);
const migration = readFileSync(new URL('../migrations/001_university_parking.sql', import.meta.url), 'utf8');
await db.exec(migration);
await db.exec(migration); // Additive migration remains rerunnable.
await db.query('insert into auth.users(id) values ($1),($2)', [user1,user2]);
let passed = 0;
async function check(name, fn) { await fn(); passed++; console.log(`PASS ${name}`); }
async function asUser(user, sql, params=[]) {
  await db.exec('begin; set local role authenticated;');
  try {
    await db.query("select set_config('request.jwt.claim.sub',$1,true)",[user]);
    const result = await db.query(sql, params);
    await db.exec('commit');
    return result;
  } catch(e) { await db.exec('rollback'); throw e; }
}
async function ingest(code, occupied) {
  await db.exec('begin; set local role service_role;');
  try {
    const result = await db.query('select * from public.ingest_sensor($1,$2)',[code,occupied]);
    await db.exec('commit'); return result;
  } catch(e) { await db.exec('rollback'); throw e; }
}
const scalar = result => Object.values(result.rows[0])[0];
await check('empty report has no invented usage or average', async()=>{
  const report = scalar(await asUser(user1,'select public.parking_report()'));
  assert.equal(report.utilization_percent,null); assert.equal(report.average_minutes,null);
});
await check('unseen sensor cannot be reserved',async()=>{
  await assert.rejects(asUser(user1,"select public.reserve_slot('A01',15)"),/Cảm biến mất kết nối/);
});
await check('driver cannot ingest telemetry',async()=>{
  await assert.rejects(asUser(user1,"select public.ingest_sensor('A01',false)"),/permission denied/);
});
await check('driver cannot write slot directly',async()=>{
  await assert.rejects(asUser(user1,"update public.parking_slots set sensor_occupied=false"),/permission denied/);
});
await check('unknown sensor code is not auto-created',async()=>{
  assert.equal((await ingest('A99',false)).rows.length,0);
});
await ingest('A01',false);
let booking1;
await check('free slot can be reserved',async()=>{
  booking1=scalar(await asUser(user1,"select public.reserve_slot('A01',15)"));
  assert.equal(booking1.slot_code,'A01');
});
await check('second driver cannot take held slot',async()=>{
  await assert.rejects(asUser(user2,"select public.reserve_slot('A01',15)"),/đã được đặt trước/);
});
await check('reservation RLS hides another driver',async()=>{
  assert.equal((await asUser(user2,'select * from public.parking_reservations')).rows.length,0);
});
await check('another driver cannot cancel reservation',async()=>{
  await assert.rejects(asUser(user2,'select public.cancel_reservation($1)',[booking1.id]),/của bạn/);
});
await check('confirmation requires occupied telemetry',async()=>{
  await assert.rejects(asUser(user1,"select public.confirm_parked('A01')"),/phát hiện có xe/);
});
await ingest('A01',true);
await check('occupied held slot cannot be claimed by another driver',async()=>{
  await assert.rejects(asUser(user2,"select public.confirm_parked('A01')"),/người khác đặt trước/);
});
await check('confirmation completes booking and saves position',async()=>{
  await asUser(user1,"select public.confirm_parked('A01')");
  await asUser(user1,"select public.confirm_parked('A01')"); // Retry is safe.
  assert.equal(scalar(await asUser(user1,'select status from public.parking_reservations')),'checked_in');
  assert.equal(scalar(await asUser(user1,'select source from public.parking_positions')),'confirmed');
  assert.equal((await asUser(user1,'select * from public.parking_visits where ended_at is null')).rows.length,1);
});
await check('position is private',async()=>{
  assert.equal((await asUser(user2,'select * from public.parking_positions')).rows.length,0);
});
await check('heartbeat does not create duplicate periods',async()=>{
  const before=scalar(await db.query('select count(*) from public.parking_sensor_periods'));
  await ingest('A01',true);
  assert.equal(scalar(await db.query('select count(*) from public.parking_sensor_periods')),before);
});
await check('free telemetry closes confirmed visit',async()=>{
  await ingest('A01',false);
  assert.equal(scalar(await asUser(user1,'select end_reason from public.parking_visits')),'vehicle_left');
});
let expired;
await check('expired hold can be reclaimed before cron runs',async()=>{
  expired=scalar(await asUser(user1,"select public.reserve_slot('A01',1)"));
  await db.exec("update public.parking_reservations set expires_at=now()-interval '1 minute' where status='active'; update public.parking_slots set reserved_until=now()-interval '1 minute' where code='A01';");
  await asUser(user2,"select public.reserve_slot('A01',15)");
  assert.equal(scalar(await asUser(user1,'select status from public.parking_reservations where id=$1',[expired.id])),'expired');
});
await check('cancelling old hold preserves newer reservation',async()=>{
  await asUser(user1,'select public.cancel_reservation($1)',[expired.id]);
  assert.notEqual(scalar(await db.query("select reserved_until from public.parking_slots where code='A01'")),null);
});
await check('expiry task clears overdue hold',async()=>{
  await db.exec("update public.parking_reservations set expires_at=now()-interval '1 minute' where status='active'; update public.parking_slots set reserved_until=now()-interval '1 minute' where code='A01'; select public.expire_reservations();");
  assert.equal(scalar(await db.query("select reserved_until from public.parking_slots where code='A01'")),null);
});
await check('offline slot cannot be booked using old free reading',async()=>{
  await db.exec("update public.parking_slots set last_seen_at=now()-interval '1 minute' where code='A01';");
  await assert.rejects(asUser(user1,"select public.reserve_slot('A01',15)"),/mất kết nối/);
});
await check('duration bounds and unknown position are rejected',async()=>{
  await assert.rejects(asUser(user1,"select public.reserve_slot('A01',0)"),/1 đến 120/);
  await assert.rejects(asUser(user1,"select public.save_parking_position('X99','')"),/foreign key/);
});
await check('manual position updates note and source',async()=>{
  await asUser(user1,"select public.save_parking_position('B02','Gần cầu thang')");
  assert.equal(scalar(await asUser(user1,'select source from public.parking_positions')),'manual');
});
await check('aggregate report returns bounded ratios',async()=>{
  const report=scalar(await asUser(user1,'select public.parking_report()'));
  assert.ok(report.utilization_percent>=0 && report.utilization_percent<=100);
  assert.ok(report.coverage_percent>=0 && report.coverage_percent<=100);
  assert.ok(Array.isArray(report.peak_hours));
});
console.log(`${passed} database scenarios passed`);
await db.close();
