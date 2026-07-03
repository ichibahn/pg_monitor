\pset format wrapped
\echo ==========================================
\echo  Long Running Queries (running > 5 min)
\echo ==========================================
SELECT
    pid,
    usename,
    datname,
    client_addr,
    now() - query_start AS query_runtime,
    backend_xmin,
    age(backend_xmin) AS xmin_age,
    wait_event_type,
    wait_event,
    query
FROM pg_stat_activity
WHERE state = 'active'
  AND query_start < now() - interval '5 min'
  AND pid != pg_backend_pid()
ORDER BY query_start ASC;

\echo =====================================================================
\echo  Long Running Transactions (transaction open > 15 min)
\echo  * long open transactions block VACUUM and cause table/index bloat
\echo =====================================================================
SELECT
    pid,
    usename,
    datname,
    client_addr,
    state,
    ROUND(EXTRACT(EPOCH FROM (now() - xact_start))/60, 2) AS minutes_running,
    backend_xmin,
    age(backend_xmin) AS xmin_age,
    wait_event_type,
    wait_event,
    LEFT(query, 60) AS last_query
FROM pg_stat_activity
WHERE xact_start IS NOT NULL
  AND EXTRACT(EPOCH FROM (now() - xact_start))/60 > 15
  AND pid != pg_backend_pid()
ORDER BY xact_start ASC;
