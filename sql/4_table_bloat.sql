\pset format wrapped
\qecho ----------------------------------------------------------------------
\qecho Estimated table bloat (statistics-based, pgstattuple not needed).
\qecho Estimation only: verify with pgstattuple before VACUUM FULL decisions.
\qecho ----------------------------------------------------------------------
WITH constants AS (
    SELECT current_setting('block_size')::numeric AS bs, 23 AS hdr, 8 AS ma
),
per_table AS (
    SELECT
        s.schemaname,
        s.tablename,
        constants.hdr,
        constants.ma,
        constants.bs,
        SUM((1 - s.null_frac) * s.avg_width) AS datawidth,
        MAX(s.null_frac) AS maxfracsum,
        constants.hdr + (
            SELECT 1 + count(*) / 8
            FROM pg_stats s2
            WHERE s2.null_frac <> 0
              AND s2.schemaname = s.schemaname
              AND s2.tablename = s.tablename
        ) AS nullhdr
    FROM pg_stats s, constants
    WHERE s.schemaname NOT IN ('pg_catalog', 'information_schema')
    GROUP BY s.schemaname, s.tablename, constants.hdr, constants.ma, constants.bs
),
bloat_info AS (
    SELECT
        schemaname,
        tablename,
        bs,
        ma,
        (datawidth + (hdr + ma - (CASE WHEN hdr % ma = 0 THEN ma ELSE hdr % ma END)))::numeric AS datahdr,
        (maxfracsum * (nullhdr + ma - (CASE WHEN nullhdr % ma = 0 THEN ma ELSE nullhdr % ma END))) AS nullhdr2
    FROM per_table
),
table_bloat AS (
    SELECT
        b.schemaname,
        b.tablename,
        cc.relpages,
        b.bs,
        CEIL((cc.reltuples * ((b.datahdr + b.ma - (CASE WHEN b.datahdr % b.ma = 0 THEN b.ma ELSE b.datahdr % b.ma END)) + b.nullhdr2 + 4))
             / (b.bs - 20::float)) AS otta
    FROM bloat_info b
    JOIN pg_namespace nn ON nn.nspname = b.schemaname
    JOIN pg_class cc ON cc.relname = b.tablename AND cc.relnamespace = nn.oid AND cc.relkind = 'r'
    WHERE cc.reltuples >= 0
)
SELECT
    schemaname AS schema_name,
    tablename AS table_name,
    ROUND(CASE WHEN otta = 0 THEN 0.0 ELSE relpages / otta::numeric END, 1) AS bloat_ratio,
    pg_size_pretty(CASE WHEN relpages < otta THEN 0 ELSE (bs * (relpages - otta))::bigint END) AS wasted_size,
    pg_size_pretty((bs * relpages)::bigint) AS table_size
FROM table_bloat
WHERE relpages > 16
ORDER BY CASE WHEN relpages < otta THEN 0 ELSE (bs * (relpages - otta))::bigint END DESC
LIMIT 30;
