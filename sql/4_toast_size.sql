\pset format wrapped
\qecho ----------------------------------------------------------------------
\qecho Tables with TOAST storage - large TEXT/JSONB/BYTEA values live here.
\qecho High toast_pct means most of the table size is out-of-line data.
\qecho ----------------------------------------------------------------------
SELECT
    n.nspname AS schema_name,
    c.relname AS table_name,
    pg_size_pretty(pg_relation_size(c.oid)) AS heap_size,
    t.relname AS toast_name,
    pg_size_pretty(pg_total_relation_size(t.oid)) AS toast_size,
    pg_size_pretty(pg_indexes_size(c.oid)) AS index_size,
    pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size,
    round(100.0 * pg_total_relation_size(t.oid) / NULLIF(pg_total_relation_size(c.oid), 0), 1) AS toast_pct
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
JOIN pg_class t ON t.oid = c.reltoastrelid
WHERE c.reltoastrelid <> 0
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(t.oid) DESC
LIMIT 30;
