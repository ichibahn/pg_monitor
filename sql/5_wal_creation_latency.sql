\pset format wrapped
\pset footer off
SELECT EXISTS (SELECT 1 FROM pg_settings WHERE name LIKE 'apg%') AS is_aurora
\gset
\if :is_aurora
\echo '[Aurora] WAL LSN functions are restricted - Aurora manages WAL at the'
\echo 'shared storage layer. For durable LSN and replica lag, see menu 71.'
\else
SELECT pg_is_in_recovery() AS in_recovery
\gset
\if :in_recovery
\echo 'This server is in recovery (standby). WAL is received here, not generated.'
SELECT
    pg_last_wal_receive_lsn() AS receive_lsn,
    pg_last_wal_replay_lsn() AS replay_lsn,
    pg_size_pretty(pg_wal_lsn_diff(pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn())) AS replay_lag_bytes;
\else
SELECT
    pg_current_wal_lsn() AS current_write_lsn,
    pg_current_wal_insert_lsn() AS insert_lsn,
    pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_insert_lsn(), pg_current_wal_lsn())) AS inserted_not_yet_written;
\endif
\endif
