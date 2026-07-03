\pset format wrapped
SELECT current_setting('server_version_num')::int >= 160000 AS has_pg_stat_io
\gset
\if :has_pg_stat_io
SELECT
    backend_type,
    object,
    context,
    reads,
    round(read_time::numeric, 1) AS read_time_ms,
    writes,
    round(write_time::numeric, 1) AS write_time_ms,
    extends,
    hits,
    evictions,
    fsyncs
FROM pg_stat_io
WHERE reads > 0 OR writes > 0 OR extends > 0 OR hits > 0
ORDER BY (reads + writes) DESC
LIMIT 30;
\else
\echo 'pg_stat_io is available on PostgreSQL 16 or later (current server is older).'
\echo 'Use menu 23 (Transaction Stat By Database) for blks_read/blks_hit instead.'
\endif
