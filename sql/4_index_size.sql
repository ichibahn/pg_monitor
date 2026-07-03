\pset format wrapped
SELECT
    n.nspname AS schema_name,
    i.relname AS index_name,
    string_agg(a.attname, ', ') AS index_columns,
    n.nspname || '.' || t.relname AS table_name,
    pg_catalog.obj_description(i.oid, 'pg_class') AS index_comment,
    pg_size_pretty(pg_total_relation_size(i.oid)) AS index_size,
    COALESCE(NULLIF(i.reltuples::bigint, -1), 0) AS row_count
FROM pg_index idx
JOIN pg_class i ON idx.indexrelid = i.oid
JOIN pg_class t ON idx.indrelid = t.oid
JOIN pg_namespace n ON i.relnamespace = n.oid
LEFT JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = ANY(idx.indkey)
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
GROUP BY n.nspname, i.relname, t.relname, i.oid
ORDER BY pg_total_relation_size(i.oid) DESC
LIMIT 50;
