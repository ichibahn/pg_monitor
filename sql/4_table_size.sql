\pset format wrapped
SELECT t.table_schema AS schema_name,
       t.table_name,
       pg_catalog.obj_description(format('%I.%I', t.table_schema, t.table_name)::regclass::oid) AS table_comment,
       (SELECT COUNT(*)
        FROM information_schema.columns
        WHERE table_schema = t.table_schema AND table_name = t.table_name) AS column_count,
       pg_size_pretty(pg_total_relation_size(format('%I.%I', t.table_schema, t.table_name)::regclass)) AS table_size,
       COALESCE(NULLIF((SELECT reltuples::bigint
                        FROM pg_class c
                                 JOIN pg_namespace n ON c.relnamespace = n.oid
                        WHERE c.relname = t.table_name
                          AND n.nspname = t.table_schema), -1), 0) AS row_count
FROM information_schema.tables t
         JOIN pg_class c ON t.table_name = c.relname
         JOIN pg_namespace n ON c.relnamespace = n.oid AND n.nspname = t.table_schema
WHERE t.table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY t.table_catalog, t.table_schema, t.table_name
limit 50;
