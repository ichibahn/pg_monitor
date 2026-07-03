\pset format wrapped
SELECT datname AS database_name, numbackends AS current_connections, xact_commit AS commits, xact_rollback AS rollbacks,
blks_read AS disk_reads, blks_hit AS buffer_hits, tup_returned AS rows_returned, tup_fetched AS rows_fetched,
tup_inserted AS rows_inserted, tup_updated AS rows_updated, tup_deleted AS rows_deleted,
temp_files, pg_size_pretty(temp_bytes) AS temp_bytes, deadlocks
FROM pg_stat_database
WHERE datname IS NOT NULL
ORDER BY datname;
