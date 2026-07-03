\pset format wrapped
WITH RECURSIVE partition_hierarchy AS (
  -- anchor: root partitioned tables only (no parent)
  SELECT
    pg_class.oid AS oid,
    pg_namespace.nspname AS schema_name,
    pg_class.relname AS table_name,
    NULL::text COLLATE "C" AS parent_name,
    CASE
      WHEN pg_partitioned_table.partstrat = 'r' THEN 'RANGE'
      WHEN pg_partitioned_table.partstrat = 'l' THEN 'LIST'
      WHEN pg_partitioned_table.partstrat = 'h' THEN 'HASH'
      ELSE NULL
    END AS partition_type,
    0 AS level
  FROM pg_class
  JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
  LEFT JOIN pg_partitioned_table ON pg_class.oid = pg_partitioned_table.partrelid
  WHERE pg_class.relkind = 'p'
    AND NOT EXISTS (SELECT 1 FROM pg_inherits WHERE pg_inherits.inhrelid = pg_class.oid)
  UNION ALL
  -- children (leaf partitions and sub-partitioned tables)
  SELECT
    pg_class.oid AS oid,
    pg_namespace.nspname AS schema_name,
    pg_class.relname AS table_name,
    partition_hierarchy.table_name AS parent_name,
    CASE
      WHEN pg_partitioned_table.partstrat = 'r' THEN 'RANGE'
      WHEN pg_partitioned_table.partstrat = 'l' THEN 'LIST'
      WHEN pg_partitioned_table.partstrat = 'h' THEN 'HASH'
      ELSE NULL
    END AS partition_type,
    partition_hierarchy.level + 1
  FROM pg_class
  JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
  JOIN pg_inherits ON pg_class.oid = pg_inherits.inhrelid
  LEFT JOIN pg_partitioned_table ON pg_class.oid = pg_partitioned_table.partrelid
  JOIN partition_hierarchy ON pg_inherits.inhparent = partition_hierarchy.oid
)
SELECT
  schema_name,
  repeat('  ', level) || table_name AS table_name,
  partition_type,
  COALESCE(parent_name, 'Root Partition') AS parent_name,
  pg_size_pretty(pg_relation_size(oid)) AS size
FROM partition_hierarchy
ORDER BY schema_name, COALESCE(parent_name, ''), table_name;
