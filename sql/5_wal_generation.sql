\pset format wrapped
SELECT EXISTS (SELECT 1 FROM pg_settings WHERE name LIKE 'apg%') AS is_aurora
\gset
\if :is_aurora
\echo '[Aurora] pg_stat_wal is not supported - Aurora manages WAL at the shared'
\echo 'storage layer. For log throughput per instance, see menu 71'
\echo '(log_stream_speed_in_kib_per_second) or CloudWatch WAL metrics.'
\else
SELECT current_setting('server_version_num')::int >= 140000 AS ge14
\gset
\if :ge14
\qecho ----------------------------------------------------------------------
\qecho WAL generation since stats_reset (pg_stat_wal).
\qecho wal_fpi = full page images (spikes right after each checkpoint).
\qecho wal_buffers_full > 0 growing fast suggests wal_buffers is too small.
\qecho ----------------------------------------------------------------------
SELECT
    wal_records,
    wal_fpi,
    pg_size_pretty(wal_bytes) AS wal_bytes,
    wal_buffers_full,
    stats_reset,
    pg_size_pretty((wal_bytes / GREATEST(EXTRACT(EPOCH FROM (now() - stats_reset)) / 3600, 1))::numeric(38,0)) AS avg_wal_per_hour
FROM pg_stat_wal;
\else
\echo 'pg_stat_wal is available on PostgreSQL 14 or later (current server is older).'
\endif
\endif
