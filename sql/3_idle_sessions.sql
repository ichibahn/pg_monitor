\pset format wrapped
SELECT
    pid,
    backend_xmin,
    age(backend_xmin) AS xmin_age,
    usename,
    application_name,
    client_addr,
    state,
    backend_start,
    NOW() - backend_start AS session_duration,
    NOW() - state_change AS in_state_duration,
    xact_start,
    LEFT(query, 60) AS last_query
FROM pg_stat_activity
WHERE state IN ('idle', 'idle in transaction', 'idle in transaction (aborted)')
  AND pid != pg_backend_pid()
ORDER BY backend_start ASC;
