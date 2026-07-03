\pset format wrapped
\qecho ----------------------------------------------------------------------
\qecho Estimated B-tree index bloat (statistics-based, pgstattuple not needed)
\qecho Estimation only: verify with pgstattuple before REINDEX decisions.
\qecho ----------------------------------------------------------------------
WITH btree_index_atts AS (
    SELECT
        pg_namespace.nspname,
        indexclass.relname AS index_name,
        indexclass.reltuples,
        indexclass.relpages,
        pg_index.indrelid,
        pg_index.indexrelid,
        tableclass.relname AS tablename,
        regexp_split_to_table(pg_index.indkey::text, ' ')::smallint AS attnum,
        pg_index.indexrelid AS index_oid
    FROM pg_index
    JOIN pg_class indexclass ON pg_index.indexrelid = indexclass.oid
    JOIN pg_class tableclass ON pg_index.indrelid = tableclass.oid
    JOIN pg_namespace ON pg_namespace.oid = indexclass.relnamespace
    JOIN pg_am ON indexclass.relam = pg_am.oid
    WHERE pg_am.amname = 'btree'
      AND indexclass.relpages > 0
      AND pg_namespace.nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
),
index_item_sizes AS (
    SELECT
        ind_atts.nspname,
        ind_atts.index_name,
        ind_atts.reltuples,
        ind_atts.relpages,
        ind_atts.indrelid AS table_oid,
        ind_atts.index_oid,
        current_setting('block_size')::numeric AS bs,
        8 AS maxalign,
        24 AS pagehdr,
        CASE WHEN max(coalesce(pg_stats.null_frac, 0)) = 0 THEN 2 ELSE 6 END AS index_tuple_hdr,
        sum((1 - coalesce(pg_stats.null_frac, 0)) * coalesce(pg_stats.avg_width, 1024)) AS nulldatawidth
    FROM pg_attribute
    JOIN btree_index_atts ind_atts
        ON pg_attribute.attrelid = ind_atts.indexrelid AND pg_attribute.attnum = ind_atts.attnum
    JOIN pg_stats
        ON pg_stats.schemaname = ind_atts.nspname
        AND ((pg_stats.tablename = ind_atts.tablename
              AND pg_stats.attname = pg_catalog.pg_get_indexdef(pg_attribute.attrelid, pg_attribute.attnum, TRUE))
             OR (pg_stats.tablename = ind_atts.index_name AND pg_stats.attname = pg_attribute.attname))
    WHERE pg_attribute.attnum > 0
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
),
index_aligned_est AS (
    SELECT
        maxalign, bs, nspname, index_name, reltuples, relpages, table_oid, index_oid,
        coalesce(ceil(reltuples * (6
            + maxalign
            - CASE WHEN index_tuple_hdr % maxalign = 0 THEN maxalign ELSE index_tuple_hdr % maxalign END
            + nulldatawidth
            + maxalign
            - CASE WHEN nulldatawidth::integer % maxalign = 0 THEN maxalign ELSE nulldatawidth::integer % maxalign END
        )::numeric / (bs - pagehdr)::numeric), 0) AS expected
    FROM index_item_sizes
),
raw_bloat AS (
    SELECT
        iae.nspname,
        tc.relname AS table_name,
        iae.index_name,
        iae.bs * iae.relpages::bigint AS total_bytes,
        CASE WHEN iae.relpages <= iae.expected THEN 0
             ELSE iae.bs * (iae.relpages - iae.expected)::bigint END AS wasted_bytes,
        CASE WHEN iae.relpages <= iae.expected THEN 0
             ELSE round(100 * (iae.relpages - iae.expected)::numeric / iae.relpages, 1) END AS bloat_pct,
        stat.idx_scan AS index_scans
    FROM index_aligned_est iae
    JOIN pg_class tc ON tc.oid = iae.table_oid
    JOIN pg_stat_user_indexes stat ON iae.index_oid = stat.indexrelid
)
SELECT
    nspname AS schema_name,
    table_name,
    index_name,
    bloat_pct,
    pg_size_pretty(wasted_bytes) AS wasted_size,
    pg_size_pretty(total_bytes) AS index_size,
    index_scans
FROM raw_bloat
WHERE total_bytes > 131072
ORDER BY wasted_bytes DESC
LIMIT 30;
