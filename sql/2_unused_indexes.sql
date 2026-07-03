\pset format wrapped
SELECT
    schemaname AS schema_name,
    indexrelname AS index_name,
    relname AS table_name,
    pg_size_pretty(pg_relation_size(indexrelid::regclass)) AS index_size,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY idx_scan ASC;
