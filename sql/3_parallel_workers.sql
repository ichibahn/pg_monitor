\pset format wrapped
\qecho ----------------------------------------------------------------------
\qecho PostgreSQL native parallel query activity.
\qecho Note: Aurora PostgreSQL uses this same native mechanism - the storage-
\qecho level "Aurora Parallel Query" feature exists on Aurora MySQL only.
\qecho ----------------------------------------------------------------------
\echo ==============================
\echo  Parallel Query Parameters
\echo ==============================
SELECT name, setting, short_desc
FROM pg_settings
WHERE name IN (
'max_worker_processes',
'max_parallel_workers',
'max_parallel_workers_per_gather',
'max_parallel_maintenance_workers',
'parallel_setup_cost',
'parallel_tuple_cost',
'min_parallel_table_scan_size',
'min_parallel_index_scan_size')
ORDER BY name;

\echo =========================================
\echo  Running Parallel Queries (by leader)
\echo =========================================
SELECT
    l.pid AS leader_pid,
    l.usename,
    l.datname,
    count(w.pid) AS parallel_workers,
    now() - l.query_start AS runtime,
    LEFT(l.query, 80) AS query
FROM pg_stat_activity l
JOIN pg_stat_activity w ON w.leader_pid = l.pid AND w.pid <> l.pid
WHERE w.backend_type = 'parallel worker'
GROUP BY l.pid, l.usename, l.datname, l.query_start, l.query
ORDER BY parallel_workers DESC;
