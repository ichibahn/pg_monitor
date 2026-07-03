\pset format wrapped
SELECT 
    archived_count,
    last_archived_wal,
    last_archived_time,
    failed_count,
    last_failed_wal,
    last_failed_time,
    CASE
        WHEN last_failed_time > last_archived_time THEN 'WARN: last failure is newer than last success (check archive_command and target storage)'
        WHEN last_archived_time IS NULL AND failed_count > 0 THEN 'CRIT: only failures so far (archiving never succeeded)'
        WHEN last_archived_time IS NULL THEN 'SKIP: no archives yet (archive_mode off or no WAL to archive)'
        ELSE 'OK: archiving is running'
    END AS archive_status
FROM pg_stat_archiver;
