\pset format wrapped
\qecho ----------------------------------------------------------------------
\qecho Tables not vacuumed/analyzed for 7+ days (or never).
\qecho Check autovacuum settings or run manual VACUUM ANALYZE on hot tables.
\qecho ----------------------------------------------------------------------
SELECT
    schemaname AS schema_name,
    relname AS table_name,
    n_live_tup,
    n_dead_tup,
    n_mod_since_analyze,
    GREATEST(last_vacuum, last_autovacuum) AS last_any_vacuum,
    GREATEST(last_analyze, last_autoanalyze) AS last_any_analyze,
    date_trunc('second', now() - GREATEST(last_vacuum, last_autovacuum)) AS since_vacuum,
    date_trunc('second', now() - GREATEST(last_analyze, last_autoanalyze)) AS since_analyze
FROM pg_stat_user_tables
WHERE n_live_tup > 0
  AND (GREATEST(last_vacuum, last_autovacuum) IS NULL
       OR GREATEST(last_vacuum, last_autovacuum) < now() - interval '7 days'
       OR GREATEST(last_analyze, last_autoanalyze) IS NULL
       OR GREATEST(last_analyze, last_autoanalyze) < now() - interval '7 days')
ORDER BY since_vacuum DESC NULLS FIRST
LIMIT 50;
