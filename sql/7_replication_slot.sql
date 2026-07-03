\pset format wrapped
\qecho -----------------------------------------------------------------------
\qecho wal_status
\qecho -----------------------------------------------------------------------
\qecho - reserved : claimed files are within max_wal_size.
\qecho - extended : max_wal_size is exceeded but the files are still retained.
\qecho - unreserved : the slot no longer retains the required WAL files.
\qecho - lost  : some required WAL files have been removed.
\qecho -----------------------------------------------------------------------

SELECT
    slot_name,
    slot_type,
    active,
    wal_status,
    pg_size_pretty(safe_wal_size) AS safe_wal_size,
    pg_size_pretty(pg_wal_lsn_diff(
        CASE WHEN pg_is_in_recovery() THEN pg_last_wal_replay_lsn() ELSE pg_current_wal_lsn() END,
        COALESCE(confirmed_flush_lsn, restart_lsn))) AS retained_wal,
    CASE
        WHEN wal_status IN ('unreserved', 'lost') THEN 'DANGER: required WAL is being removed'
        WHEN NOT active THEN 'WARNING: inactive slot keeps retaining WAL'
        WHEN wal_status = 'extended' THEN 'WARNING: retained WAL exceeds max_wal_size'
        ELSE 'OK'
    END AS status_check
FROM pg_replication_slots
ORDER BY slot_name;
