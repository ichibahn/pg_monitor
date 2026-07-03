\pset format wrapped
SELECT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_stat_statements') AS has_pss
\gset
\if :has_pss
SELECT
    query,
    calls,
    ROUND((total_exec_time / 1000)::numeric, 2) AS total_time_in_seconds,
    ROUND(mean_exec_time::numeric, 2) AS avg_time_in_ms,
    rows,
    shared_blks_hit,
    shared_blks_read,
    CASE
        WHEN shared_blks_hit + shared_blks_read = 0 THEN 0
        ELSE ROUND((shared_blks_hit::numeric / (shared_blks_hit + shared_blks_read)) * 100, 2)
    END AS hit_ratio
FROM pg_stat_statements
WHERE query NOT ILIKE '%pg_stat_statements%'
ORDER BY total_exec_time DESC
LIMIT 30;
\else
\echo 'pg_stat_statements extension is not installed in this database.'
\echo 'To enable it:'
\echo '  1. Add pg_stat_statements to shared_preload_libraries (restart required).'
\echo '     On RDS/Aurora: set it in the DB parameter group.'
\echo '  2. Run: CREATE EXTENSION pg_stat_statements;'
\endif
