\pset border 2
\pset linestyle unicode
\pset format wrapped
\pset footer off

\echo ==========================
\echo  Column Alignment Info
\echo ==========================
SELECT 
    a.attname AS column_name,
    pg_catalog.format_type(a.atttypid, a.atttypmod) AS data_type,
    t.typname,
    t.typalign,
    t.typlen
FROM pg_attribute a
JOIN pg_type t ON a.atttypid = t.oid
JOIN pg_class c ON a.attrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE c.relname = :'TB_NAME'
  AND n.nspname = :'SCHEMA_NAME'
  AND a.attnum > 0
  AND NOT a.attisdropped
ORDER BY a.attnum;


\echo ==========================
\echo  Padding Info (1 Row)
\echo ==========================
WITH RECURSIVE column_info AS (
    SELECT 
        c.ordinal_position::integer AS original_pos,
        c.column_name::text,
        c.data_type,
        t.typalign::bpchar AS typalign,
        t.typlen::integer AS typlen,
        t.typname,
        CASE 
            WHEN t.typlen > 0 AND t.typalign = 'd' THEN 1  
            WHEN t.typlen > 0 AND t.typalign = 'i' THEN 2  
            WHEN t.typlen > 0 AND t.typalign = 's' THEN 3  
            WHEN t.typlen > 0 AND t.typalign = 'c' THEN 4  
            WHEN t.typlen = -1 AND t.typalign = 'i' AND t.typname = 'numeric' THEN 5 
            WHEN t.typlen = -1 AND t.typalign = 'c' AND t.typname IN ('varchar', 'bpchar') THEN 6 
            WHEN t.typlen = -1 AND t.typalign = 'c' AND t.typname IN ('text', 'bytea', 'jsonb') THEN 7 
            ELSE 8 
        END AS priority
    FROM information_schema.columns c
    JOIN pg_class pc ON pc.relname = c.table_name
    JOIN pg_namespace pn ON pn.nspname = c.table_schema AND pc.relnamespace = pn.oid
    JOIN LATERAL (
        SELECT typalign, typlen, typname 
        FROM pg_type 
        WHERE typname = regexp_replace(c.udt_name, '\[\]$', '')
    ) t ON true
    WHERE c.table_name = :'TB_NAME' 
      AND c.table_schema = :'SCHEMA_NAME'  
      AND c.column_name NOT LIKE 'ctid'  
),
align_map AS (
    SELECT DISTINCT 
        t.typalign,
        CASE t.typalign
            WHEN 'd' THEN 8
            WHEN 'i' THEN 4
            WHEN 's' THEN 2
            WHEN 'c' THEN 1
            ELSE 1
        END AS align_size
    FROM pg_type t
),
col_sizes AS (
    SELECT 
        ci.*,
        am.align_size,
        CASE WHEN ci.typlen > 0 THEN ci.typlen ELSE 4 END AS data_len 
    FROM column_info ci
    JOIN align_map am ON ci.typalign = am.typalign
),
original_ordered AS (
    SELECT *, row_number() OVER (ORDER BY original_pos) AS rn
    FROM col_sizes
),
original_cum AS (
    SELECT 
        original_pos,
        column_name,
        data_len,
        align_size,
        0::bigint AS start_offset,
        0::bigint AS pad,
        data_len::bigint AS total_offset,
        rn
    FROM original_ordered 
    WHERE rn = 1
    UNION ALL
    SELECT 
        oo.original_pos,
        oo.column_name,
        oo.data_len,
        oo.align_size,
        oc.total_offset::bigint AS start_offset,
        CASE WHEN MOD(oc.total_offset, oo.align_size) = 0 THEN 0 ELSE oo.align_size - MOD(oc.total_offset, oo.align_size) END::bigint AS pad,
        oc.total_offset + CASE WHEN MOD(oc.total_offset, oo.align_size) = 0 THEN 0 ELSE oo.align_size - MOD(oc.total_offset, oo.align_size) END + oo.data_len::bigint AS total_offset,
        oo.rn
    FROM original_cum oc
    JOIN original_ordered oo ON oo.rn = oc.rn + 1
)
SELECT 
    o.orig_max::integer AS total_size,
    si.sum_individual::integer AS sum_individual,
    (o.orig_max - si.sum_individual)::integer AS padding_bytes,
    ROUND(((o.orig_max - si.sum_individual)::numeric / o.orig_max * 100), 2) AS padding_percent
FROM (
    SELECT COALESCE(MAX(total_offset), 0) AS orig_max FROM original_cum
) o
CROSS JOIN (
    SELECT COALESCE(SUM(data_len), 0) AS sum_individual FROM col_sizes
) si;


\echo ==========================
\echo  Column Order Suggestion
\echo ==========================
SELECT 
    a.attnum::integer AS original_pos, 
    a.attname::text AS column_name, 
    pg_catalog.format_type(a.atttypid, a.atttypmod) AS data_type,
    t.typalign::bpchar AS typalign, 
    t.typlen::integer AS typlen, 
    CASE 
        WHEN t.typlen > 0 AND t.typalign = 'd' THEN 1 
        WHEN t.typlen > 0 AND t.typalign = 'i' THEN 2
        WHEN t.typlen > 0 AND t.typalign = 's' THEN 3 
        WHEN t.typlen > 0 AND t.typalign = 'c' THEN 4  
        WHEN t.typlen = -1 AND t.typalign = 'i' AND t.typname = 'numeric' THEN 5 
        WHEN t.typlen = -1 AND t.typalign = 'c' AND t.typname IN ('varchar', 'bpchar') THEN 6 
        WHEN t.typlen = -1 AND t.typalign = 'c' AND t.typname IN ('text', 'bytea', 'jsonb') THEN 7
        ELSE 8 
    END AS priority,
    row_number() OVER (PARTITION BY 
        CASE 
            WHEN t.typlen > 0 AND t.typalign = 'd' THEN 1
            WHEN t.typlen > 0 AND t.typalign = 'i' THEN 2
            WHEN t.typlen > 0 AND t.typalign = 's' THEN 3
            WHEN t.typlen > 0 AND t.typalign = 'c' THEN 4
            WHEN t.typlen = -1 AND t.typalign = 'i' AND t.typname = 'numeric' THEN 5
            WHEN t.typlen = -1 AND t.typalign = 'c' AND t.typname IN ('varchar', 'bpchar') THEN 6
            WHEN t.typlen = -1 AND t.typalign = 'c' AND t.typname IN ('text', 'bytea', 'jsonb') THEN 7
            ELSE 8
        END 
        ORDER BY t.typlen DESC NULLS LAST  
    )::text AS suggested_order
FROM pg_attribute a
JOIN pg_type t ON a.atttypid = t.oid
JOIN pg_class c ON a.attrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE c.relname = :'TB_NAME'
  AND n.nspname = :'SCHEMA_NAME'
  AND a.attnum > 0
  AND NOT a.attisdropped
ORDER BY priority, t.typlen DESC NULLS LAST;
