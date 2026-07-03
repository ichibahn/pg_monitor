\pset format wrapped
SELECT 
    archived_count,
    last_archived_wal,
    last_archived_time,
    failed_count,
    last_failed_wal,
    last_failed_time,
    CASE 
        WHEN last_failed_time > last_archived_time THEN 'Archive is failing'
        WHEN last_archived_time IS NULL THEN 'No archives yet'
        ELSE 'Archiving is running'
    END AS archive_status
FROM pg_stat_archiver;
