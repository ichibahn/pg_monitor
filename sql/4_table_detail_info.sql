\pset border 2
\pset linestyle unicode
\pset format wrapped
\pset footer off

\echo ====================================
\echo  Table Basic Info (Row Count, Size)
\echo ====================================
SELECT
    n.nspname AS schema_name,
    c.relname AS table_name,
    CASE c.relkind WHEN 'p' THEN 'partitioned table' WHEN 'r' THEN 'table' ELSE c.relkind::text END AS kind,
    c.reltuples::bigint AS estimated_row_count,
    CASE WHEN c.relkind = 'p'
         THEN (SELECT sum(pg_total_relation_size(pt.relid)) FROM pg_partition_tree(c.oid) pt)::bigint / 1024 / 1024
         ELSE pg_total_relation_size(c.oid) / 1024 / 1024
    END AS total_size_mb,
    pg_table_size(c.oid) / 1024 / 1024 AS table_size_mb,
    pg_indexes_size(c.oid) / 1024 / 1024 AS index_size_mb
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = :'SCHEMA_NAME' AND c.relname = :'TB_NAME';


\echo ========================================
\echo  Table Option (Autovacuum Enable, etc.)
\echo ========================================
SELECT
    n.nspname AS schema_name,
    c.relname AS table_name,
    c.reloptions
FROM
    pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE
    n.nspname = :'SCHEMA_NAME'
    AND c.relname = :'TB_NAME';


\echo ============================
\echo  Vacuum and Analyze History 
\echo ============================
SELECT 
    schemaname,
    relname,
    last_vacuum,
    last_autovacuum,
    vacuum_count,
    autovacuum_count,
    last_analyze,
    last_autoanalyze,
    analyze_count,
    autoanalyze_count
FROM pg_stat_user_tables
WHERE schemaname = :'SCHEMA_NAME' AND relname = :'TB_NAME';

\echo ===================
\echo  Index Information
\echo ===================
SELECT 
    i.relname AS index_name,
    idx.indisprimary AS is_primary,
    idx.indisunique AS is_unique,
    pg_get_indexdef(idx.indexrelid) AS index_definition,
    pg_size_pretty(pg_relation_size(i.oid)) AS index_size
FROM pg_index idx
JOIN pg_class i ON i.oid = idx.indexrelid
JOIN pg_class t ON t.oid = idx.indrelid
JOIN pg_namespace n ON n.oid = t.relnamespace
WHERE n.nspname = :'SCHEMA_NAME' AND t.relname = :'TB_NAME';

\echo =============
\echo  Constraints
\echo =============
SELECT 
    conname AS constraint_name,
    contype AS constraint_type,
    pg_get_constraintdef(c.oid) AS constraint_definition
FROM pg_constraint c
JOIN pg_class t ON t.oid = c.conrelid
JOIN pg_namespace n ON n.oid = t.relnamespace
WHERE n.nspname = :'SCHEMA_NAME' AND t.relname = :'TB_NAME'
ORDER BY contype;

\echo ==========
\echo  Triggers
\echo ==========
SELECT 
    tgname AS trigger_name,
    tgenabled AS trigger_enabled,
    pg_get_triggerdef(t.oid) AS trigger_definition
FROM pg_trigger t
JOIN pg_class c ON c.oid = t.tgrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = :'SCHEMA_NAME' AND c.relname = :'TB_NAME' AND NOT tgisinternal;

\echo ===================================================
\echo  Related Objects (Views, Materialized Views, etc.)
\echo ===================================================
SELECT 
    n.nspname AS schema_name,
    c.relname AS object_name,
    c.relkind AS object_type,
    d.description AS comment
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_description d ON d.objoid = c.oid
WHERE c.oid IN (
    SELECT d.objid
    FROM pg_depend d
    JOIN pg_class t ON t.oid = d.refobjid
    JOIN pg_namespace n ON n.oid = t.relnamespace
    WHERE n.nspname = :'SCHEMA_NAME' AND t.relname = :'TB_NAME'
    AND d.classid = 'pg_class'::regclass
)
AND c.relname != :'TB_NAME';

\echo ====================================
\echo  Table Statistics (Access Patterns)
\echo ====================================
SELECT 
    schemaname,
    relname,
    seq_scan,
    seq_tup_read,
    idx_scan,
    idx_tup_fetch,
    n_tup_ins,
    n_tup_upd,
    n_tup_del,
    n_live_tup,
    n_dead_tup
FROM pg_stat_user_tables
WHERE schemaname = :'SCHEMA_NAME' AND relname = :'TB_NAME';

\echo ====================
\echo  Column Information 
\echo ====================
SELECT 
    a.attname AS column_name,
    pg_catalog.format_type(a.atttypid, a.atttypmod) AS data_type,
    a.attnotnull AS not_null,
    pg_get_expr(ad.adbin, ad.adrelid) AS default_value,
    d.description AS comment
FROM pg_attribute a
LEFT JOIN pg_attrdef ad ON a.attrelid = ad.adrelid AND a.attnum = ad.adnum
LEFT JOIN pg_description d ON d.objoid = a.attrelid AND d.objsubid = a.attnum
JOIN pg_class c ON c.oid = a.attrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = :'SCHEMA_NAME' AND c.relname = :'TB_NAME' AND a.attnum > 0 AND NOT a.attisdropped
ORDER BY a.attnum;

