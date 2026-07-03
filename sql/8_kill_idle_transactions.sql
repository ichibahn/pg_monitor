\pset format wrapped
\echo ==========================================================
\echo  Idle-in-transaction sessions older than given minutes
\echo ==========================================================
SELECT
    pid,
    usename,
    datname,
    client_addr,
    date_trunc('second', now() - xact_start) AS xact_age,
    LEFT(query, 60) AS last_query
FROM pg_stat_activity
WHERE state IN ('idle in transaction', 'idle in transaction (aborted)')
  AND xact_start < now() - make_interval(mins => :MINUTES)
  AND pid != pg_backend_pid()
ORDER BY xact_start;

\if :MODE_KILL
\echo ==========================================================
\echo  Terminating the sessions listed above...
\echo ==========================================================
SELECT
    pid,
    pg_terminate_backend(pid) AS terminated
FROM pg_stat_activity
WHERE state IN ('idle in transaction', 'idle in transaction (aborted)')
  AND xact_start < now() - make_interval(mins => :MINUTES)
  AND pid != pg_backend_pid();
\endif
