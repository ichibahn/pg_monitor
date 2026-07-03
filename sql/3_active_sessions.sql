\pset format wrapped
SELECT
    pid,
    backend_xmin,
    age(backend_xmin) AS xmin_age,
    now() - query_start AS runtime,
    datname,
    usename,
    state,
    wait_event_type,
    wait_event,
    query
FROM pg_stat_activity
WHERE state = 'active'
and pid <> pg_backend_pid()
ORDER BY runtime DESC
LIMIT 20;
