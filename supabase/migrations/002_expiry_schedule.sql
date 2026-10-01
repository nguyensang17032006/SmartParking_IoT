-- Enable the pg_cron extension in Supabase before running this script.
-- The deadline is enforced by reserve_slot even between scheduler runs.
select cron.schedule(
    'parking-expire-reservations',
    '* * * * *',
    'select public.expire_reservations();'
);
