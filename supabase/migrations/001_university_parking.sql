-- MVP: university car park. Apply once, in order, in Supabase SQL Editor.
begin;

create table if not exists public.parking_slots (
    id uuid primary key default gen_random_uuid(),
    code text not null unique,
    sensor_occupied boolean,
    last_seen_at timestamptz,
    reserved_until timestamptz,
    map_x double precision not null default 0.5,
    map_y double precision not null default 0.5
);
alter table public.parking_slots
    add column if not exists sensor_occupied boolean,
    add column if not exists last_seen_at timestamptz,
    add column if not exists reserved_until timestamptz,
    add column if not exists map_x double precision not null default 0.5,
    add column if not exists map_y double precision not null default 0.5;
alter table public.parking_slots alter column sensor_occupied drop not null;
alter table public.parking_slots alter column sensor_occupied drop default;
create unique index if not exists parking_slots_code_mvp_idx on public.parking_slots(code);

insert into public.parking_slots(code, map_x, map_y)
values ('A01',0.2,0.25),('A02',0.5,0.25),('A03',0.8,0.25),
       ('B01',0.2,0.75),('B02',0.5,0.75),('B03',0.8,0.75)
on conflict(code) do nothing;
-- Give untouched/default coordinates the sample layout; preserve custom maps.
update public.parking_slots ps set map_x=layout.x,map_y=layout.y
from (values ('A01',0.2,0.25),('A02',0.5,0.25),('A03',0.8,0.25),
             ('B01',0.2,0.75),('B02',0.5,0.75),('B03',0.8,0.75)) as layout(code,x,y)
where ps.code=layout.code and ps.map_x=0.5 and ps.map_y=0.5;

create table if not exists public.parking_reservations (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    slot_code text not null references public.parking_slots(code),
    status text not null default 'active'
        check(status in ('active','cancelled','expired','checked_in')),
    created_at timestamptz not null default now(),
    expires_at timestamptz not null
);
create index if not exists reservations_expiry_idx
    on public.parking_reservations(expires_at) where status='active';
create table if not exists public.parking_positions (
    user_id uuid primary key references auth.users(id) on delete cascade,
    slot_code text not null references public.parking_slots(code),
    note text not null default '',
    source text not null check(source in ('manual','confirmed')),
    saved_at timestamptz not null default now()
);
create table if not exists public.parking_visits (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    slot_code text not null references public.parking_slots(code),
    started_at timestamptz not null default now(),
    ended_at timestamptz,
    end_reason text
);
create unique index if not exists visits_active_slot_idx
    on public.parking_visits(slot_code) where ended_at is null;
create unique index if not exists visits_active_user_idx
    on public.parking_visits(user_id) where ended_at is null;
-- Periods represent observations with a maximum 30s heartbeat lease.
-- Unobserved time is excluded from utilization, rather than assumed empty.
create table if not exists public.parking_sensor_periods (
    id bigint generated always as identity primary key,
    slot_code text not null references public.parking_slots(code),
    occupied boolean not null,
    started_at timestamptz not null,
    observed_until timestamptz not null
);
create index if not exists sensor_periods_time_idx
    on public.parking_sensor_periods(slot_code,started_at);

alter table public.parking_slots enable row level security;
alter table public.parking_reservations enable row level security;
alter table public.parking_positions enable row level security;
alter table public.parking_visits enable row level security;
alter table public.parking_sensor_periods enable row level security;
revoke all on public.parking_slots,public.parking_reservations,
    public.parking_positions,public.parking_visits,public.parking_sensor_periods
    from anon,authenticated;
grant select on public.parking_slots,public.parking_reservations,
    public.parking_positions,public.parking_visits to authenticated;
grant all on public.parking_slots,public.parking_reservations,
    public.parking_positions,public.parking_visits,public.parking_sensor_periods
    to service_role;
grant usage,select on sequence public.parking_sensor_periods_id_seq to service_role;

drop policy if exists parking_mvp_read on public.parking_slots;
create policy parking_mvp_read on public.parking_slots
    for select to authenticated using(true);
drop policy if exists reservations_own on public.parking_reservations;
create policy reservations_own on public.parking_reservations
    for select to authenticated using(user_id=(select auth.uid()));
drop policy if exists positions_own on public.parking_positions;
create policy positions_own on public.parking_positions
    for select to authenticated using(user_id=(select auth.uid()));
drop policy if exists visits_own on public.parking_visits;
create policy visits_own on public.parking_visits
    for select to authenticated using(user_id=(select auth.uid()));

-- Mutations use narrow RPCs. Clients cannot directly write slot state or
-- another user's reservation. Every SECURITY DEFINER has an empty search_path.
create or replace function public.ingest_sensor(p_code text,p_occupied boolean)
returns table(code text,sensor_occupied boolean,last_seen_at timestamptz)
language plpgsql security definer set search_path='' as $$
declare
    s public.parking_slots%rowtype;
    t timestamptz := clock_timestamp();
    period_id bigint;
begin
    if p_occupied is null then raise exception 'occupied phải là boolean'; end if;
    select * into s from public.parking_slots ps where ps.code=p_code for update;
    if not found then return; end if;
    select sp.id into period_id from public.parking_sensor_periods sp
        where sp.slot_code=p_code order by sp.started_at desc limit 1;
    if s.last_seen_at is not null and t <= s.last_seen_at+interval '30 seconds'
       and s.sensor_occupied=p_occupied and period_id is not null then
        update public.parking_sensor_periods set observed_until=t+interval '30 seconds'
            where id=period_id;
    else
        if period_id is not null then
            update public.parking_sensor_periods
                set observed_until=least(observed_until,t) where id=period_id;
        end if;
        insert into public.parking_sensor_periods(slot_code,occupied,started_at,observed_until)
            values(p_code,p_occupied,t,t+interval '30 seconds');
    end if;
    -- Loss of telemetry breaks certainty about an active parking visit.
    if s.last_seen_at is not null and t>s.last_seen_at+interval '30 seconds' then
        update public.parking_visits
            set ended_at=greatest(started_at,s.last_seen_at+interval '30 seconds'),
                end_reason='sensor_lost'
            where slot_code=p_code and ended_at is null;
    end if;
    if not p_occupied then
        update public.parking_visits set ended_at=t,end_reason='vehicle_left'
            where slot_code=p_code and ended_at is null;
    end if;
    update public.parking_slots ps set sensor_occupied=p_occupied,last_seen_at=t
        where ps.code=p_code;
    return query select ps.code,ps.sensor_occupied,ps.last_seen_at
        from public.parking_slots ps where ps.code=p_code;
end $$;

create or replace function public.expire_reservations()
returns void language plpgsql security definer set search_path='' as $$
begin
    -- Lock slots first, in a stable order, matching the other mutations.
    perform 1 from public.parking_slots ps
        where ps.reserved_until<=now() order by ps.code for update;
    update public.parking_reservations set status='expired'
        where status='active' and expires_at<=now();
    update public.parking_slots set reserved_until=null where reserved_until<=now();
    update public.parking_visits pv
        set ended_at=greatest(pv.started_at,ps.last_seen_at+interval '30 seconds'),
            end_reason='sensor_lost'
        from public.parking_slots ps where pv.slot_code=ps.code
          and pv.ended_at is null and ps.last_seen_at<now()-interval '30 seconds';
end $$;

create or replace function public.reserve_slot(p_code text,p_minutes integer)
returns jsonb language plpgsql security definer set search_path='' as $$
declare
    u uuid:=auth.uid();
    s public.parking_slots%rowtype;
    r public.parking_reservations%rowtype;
begin
    if u is null then raise exception 'Vui lòng đăng nhập'; end if;
    if p_minutes is null or p_minutes<1 or p_minutes>120 then
        raise exception 'Thời gian giữ chỗ phải từ 1 đến 120 phút';
    end if;
    perform pg_advisory_xact_lock(hashtextextended(u::text,0));
    select * into s from public.parking_slots ps where ps.code=p_code for update;
    if not found then raise exception 'Không tìm thấy ô đỗ'; end if;
    if s.last_seen_at is null or s.last_seen_at<=now()-interval '30 seconds'
       or s.sensor_occupied is null then raise exception 'Cảm biến mất kết nối'; end if;
    if s.sensor_occupied then raise exception 'Ô đỗ đã có xe'; end if;
    if s.reserved_until>now() then raise exception 'Ô đỗ đã được đặt trước'; end if;
    if exists(select 1 from public.parking_reservations
              where user_id=u and status='active' and expires_at>now()) then
        raise exception 'Bạn đang có một chỗ đặt trước';
    end if;
    if exists(select 1 from public.parking_visits pv join public.parking_slots ps
              on ps.code=pv.slot_code where pv.user_id=u and pv.ended_at is null
              and ps.last_seen_at>now()-interval '30 seconds') then
        raise exception 'Bạn đang có phiên đỗ xe';
    end if;
    update public.parking_reservations set status='expired'
        where slot_code=p_code and status='active' and expires_at<=now();
    insert into public.parking_reservations(user_id,slot_code,expires_at)
        values(u,p_code,now()+make_interval(mins=>p_minutes)) returning * into r;
    update public.parking_slots set reserved_until=r.expires_at where code=p_code;
    return to_jsonb(r);
end $$;

create or replace function public.cancel_reservation(p_id uuid)
returns void language plpgsql security definer set search_path='' as $$
declare r public.parking_reservations%rowtype;
begin
    if auth.uid() is null then raise exception 'Vui lòng đăng nhập'; end if;
    select * into r from public.parking_reservations where id=p_id and user_id=auth.uid();
    if not found then raise exception 'Không tìm thấy lượt đặt chỗ của bạn'; end if;
    perform 1 from public.parking_slots where code=r.slot_code for update;
    update public.parking_reservations
        set status=case when expires_at<=now() then 'expired' else 'cancelled' end
        where id=p_id and user_id=auth.uid() and status='active';
    if found and not exists(select 1 from public.parking_reservations
         where slot_code=r.slot_code and status='active' and expires_at>now()) then
        update public.parking_slots set reserved_until=null where code=r.slot_code;
    end if;
end $$;

create or replace function public.save_parking_position(p_code text,p_note text default '')
returns void language plpgsql security definer set search_path='' as $$
begin
    if auth.uid() is null then raise exception 'Vui lòng đăng nhập'; end if;
    if length(coalesce(p_note,''))>200 then raise exception 'Ghi chú tối đa 200 ký tự'; end if;
    insert into public.parking_positions(user_id,slot_code,note,source)
        values(auth.uid(),p_code,coalesce(p_note,''),'manual')
        on conflict(user_id) do update set slot_code=excluded.slot_code,
            note=excluded.note,source='manual',saved_at=now();
end $$;

create or replace function public.confirm_parked(p_code text)
returns void language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); s public.parking_slots%rowtype;
begin
    if u is null then raise exception 'Vui lòng đăng nhập'; end if;
    perform pg_advisory_xact_lock(hashtextextended(u::text,0));
    select * into s from public.parking_slots where code=p_code for update;
    if not found then raise exception 'Không tìm thấy ô đỗ'; end if;
    if s.last_seen_at is null or s.last_seen_at<=now()-interval '30 seconds'
       or s.sensor_occupied is distinct from true then
        raise exception 'Cần cảm biến đang kết nối và phát hiện có xe';
    end if;
    if exists(select 1 from public.parking_reservations where slot_code=p_code
        and status='active' and expires_at>now() and user_id<>u) then
        raise exception 'Ô này đang được người khác đặt trước';
    end if;
    if exists(select 1 from public.parking_reservations where user_id=u
        and status='active' and expires_at>now() and slot_code<>p_code) then
        raise exception 'Hãy hủy chỗ đặt cũ trước khi xác nhận ở ô khác';
    end if;
    -- Retry is idempotent for the same user/slot.
    if exists(select 1 from public.parking_visits where slot_code=p_code
        and user_id=u and ended_at is null) then return; end if;
    -- Clear a user's stale visit before claiming a new occupied slot.
    update public.parking_visits pv
        set ended_at=greatest(pv.started_at,ps.last_seen_at+interval '30 seconds'),
            end_reason='sensor_lost' from public.parking_slots ps
        where pv.slot_code=ps.code and pv.user_id=u and pv.ended_at is null
          and ps.last_seen_at<=now()-interval '30 seconds';
    if exists(select 1 from public.parking_visits where ended_at is null
        and (slot_code=p_code or user_id=u)) then
        raise exception 'Ô đã được xác nhận hoặc bạn đang có phiên đỗ xe';
    end if;
    update public.parking_reservations set status='checked_in'
        where user_id=u and slot_code=p_code and status='active' and expires_at>now();
    update public.parking_slots set reserved_until=null where code=p_code;
    insert into public.parking_visits(user_id,slot_code) values(u,p_code);
    insert into public.parking_positions(user_id,slot_code,note,source)
        values(u,p_code,'','confirmed') on conflict(user_id) do update
        set slot_code=excluded.slot_code,note='',source='confirmed',saved_at=now();
end $$;

create or replace function public.parking_report()
returns jsonb language plpgsql security definer set search_path='' as $$
declare
    t timestamptz:=now();
    start_time timestamptz:=now()-interval '7 days';
    observed numeric; used numeric; capacity integer;
    avg_minutes numeric; peaks jsonb;
begin
    if auth.uid() is null then raise exception 'Vui lòng đăng nhập'; end if;
    select count(*) into capacity from public.parking_slots;
    select coalesce(sum(extract(epoch from
               least(observed_until,t)-greatest(started_at,start_time))),0),
           coalesce(sum(case when occupied then extract(epoch from
               least(observed_until,t)-greatest(started_at,start_time)) else 0 end),0)
        into observed,used from public.parking_sensor_periods
        where started_at<t and observed_until>start_time;
    -- Only completed, user-confirmed visits with an observed exit.
    select avg(extract(epoch from ended_at-started_at)/60) into avg_minutes
        from public.parking_visits where ended_at>=start_time and ended_at<=t
            and end_reason='vehicle_left';
    select coalesce(jsonb_agg(to_jsonb(q) order by q.hour),'[]'::jsonb) into peaks
        from (
            select extract(hour from b.h at time zone 'Asia/Ho_Chi_Minh')::int as hour,
                sum(extract(epoch from
                    least(sp.observed_until,b.h+interval '1 hour',t)
                    -greatest(sp.started_at,b.h,start_time)))/60 as occupied_minutes
            from generate_series(date_trunc('hour',start_time),t,interval '1 hour') b(h)
            join public.parking_sensor_periods sp on sp.occupied
                and sp.started_at<least(b.h+interval '1 hour',t)
                and sp.observed_until>greatest(b.h,start_time)
            group by 1
        ) q;
    return jsonb_build_object(
        'utilization_percent',case when observed>0 then round(used/observed*100,1) else null end,
        'coverage_percent',case when capacity>0 then round(observed/(capacity*604800)*100,2) else 0 end,
        'average_minutes',round(avg_minutes,1),'peak_hours',peaks);
end $$;

revoke all on function public.ingest_sensor(text,boolean) from public,anon,authenticated;
grant execute on function public.ingest_sensor(text,boolean) to service_role;
revoke all on function public.expire_reservations() from public,anon,authenticated;
grant execute on function public.expire_reservations() to service_role;
revoke all on function public.reserve_slot(text,integer),
    public.cancel_reservation(uuid),public.save_parking_position(text,text),
    public.confirm_parked(text),public.parking_report() from public,anon;
grant execute on function public.reserve_slot(text,integer),
    public.cancel_reservation(uuid),public.save_parking_position(text,text),
    public.confirm_parked(text),public.parking_report() to authenticated;

do $$
begin
    if not exists(select 1 from pg_publication_tables
        where pubname='supabase_realtime' and schemaname='public' and tablename='parking_slots') then
        alter publication supabase_realtime add table public.parking_slots;
    end if;
end $$;
commit;
