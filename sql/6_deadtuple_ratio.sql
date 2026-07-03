\pset format wrapped
SELECT
    n.nspname AS schema_name,
    c.relname AS table_name,
    pg_stat_get_live_tuples(c.oid) + pg_stat_get_dead_tuples(c.oid) AS total_tuple,
    pg_stat_get_live_tuples(c.oid) AS live_tuple,
    pg_stat_get_dead_tuples(c.oid) AS dead_tuple,
    round(100.0 * pg_stat_get_live_tuples(c.oid) / (pg_stat_get_live_tuples(c.oid) + pg_stat_get_dead_tuples(c.oid)), 2) AS live_tuple_rate,
    round(100.0 * pg_stat_get_dead_tuples(c.oid) / (pg_stat_get_live_tuples(c.oid) + pg_stat_get_dead_tuples(c.oid)), 2) AS dead_tuple_rate,
    pg_size_pretty(pg_total_relation_size(c.oid)) AS total_table_size,
    pg_size_pretty(pg_relation_size(c.oid)) AS table_size
FROM pg_class AS c
JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
WHERE pg_stat_get_live_tuples(c.oid) > 0
AND c.relkind IN ('r', 'm', 'p')
AND n.nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
ORDER BY dead_tuple DESC
LIMIT 50;
