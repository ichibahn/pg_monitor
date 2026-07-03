\pset format wrapped
\qecho ----------------------------------------------------------------------
\qecho Foreign keys whose referencing columns have no covering index.
\qecho DELETE/UPDATE on the referenced table seq-scans these tables and
\qecho can cause long lock waits.
\qecho ----------------------------------------------------------------------
SELECT
    c.conrelid::regclass AS table_name,
    c.conname AS fk_name,
    string_agg(a.attname, ', ' ORDER BY x.n) AS fk_columns,
    pg_size_pretty(pg_relation_size(c.conrelid)) AS table_size,
    c.confrelid::regclass AS referenced_table
FROM pg_constraint c
CROSS JOIN LATERAL unnest(c.conkey) WITH ORDINALITY AS x(attnum, n)
JOIN pg_attribute a ON a.attnum = x.attnum AND a.attrelid = c.conrelid
WHERE c.contype = 'f'
  AND NOT EXISTS (
      SELECT 1
      FROM pg_index i
      WHERE i.indrelid = c.conrelid
        AND (i.indkey::smallint[])[0:cardinality(c.conkey)-1]
            OPERATOR(pg_catalog.@>) c.conkey
  )
GROUP BY c.conrelid, c.conname, c.confrelid
ORDER BY pg_relation_size(c.conrelid) DESC
LIMIT 50;
