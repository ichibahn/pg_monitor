\pset format wrapped
\qecho ----------------------------------------------------------------------
\qecho Indexes with identical definition (same table, columns, opclass, pred)
\qecho Dropping duplicates saves space and write overhead - verify usage first.
\qecho ----------------------------------------------------------------------
SELECT
    pg_size_pretty(sum(pg_relation_size(idx))::bigint) AS total_size,
    (array_agg(idx::text ORDER BY idx::text))[1] AS index1,
    (array_agg(idx::text ORDER BY idx::text))[2] AS index2,
    (array_agg(idx::text ORDER BY idx::text))[3] AS index3,
    (array_agg(idx::text ORDER BY idx::text))[4] AS index4
FROM (
    SELECT
        indexrelid::regclass AS idx,
        (indrelid::text || E'\n' || indclass::text || E'\n' || indkey::text || E'\n'
         || coalesce(indexprs::text, '') || E'\n' || coalesce(indpred::text, '')) AS grouping_key
    FROM pg_index
) sub
GROUP BY grouping_key
HAVING count(*) > 1
ORDER BY sum(pg_relation_size(idx)) DESC;
