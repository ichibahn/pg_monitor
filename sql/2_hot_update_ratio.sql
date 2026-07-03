\pset format wrapped
\qecho ----------------------------------------------------------------------
\qecho HOT (Heap-Only Tuple) updates require BOTH:
\qecho   1) the UPDATE does not change any indexed column
\qecho   2) free space in the same page (this is what fillfactor controls)
\qecho Lowering fillfactor only helps (2). If the ratio stays low even with
\qecho a lowered fillfactor, the cause is usually (1) - indexed-column updates.
\qecho
\qecho hot_diagnosis criteria:
\qecho   updates < 1000                  -> '- (too few updates)'
\qecho   ratio >= 20%                    -> 'OK'
\qecho   ratio < 20%, fillfactor = 100   -> 'candidate: lower fillfactor'
\qecho   ratio < 20%, fillfactor < 100   -> 'check indexed-column updates'
\qecho ----------------------------------------------------------------------
SELECT
    s.schemaname,
    s.relname,
    s.n_tup_upd AS total_updates,
    s.n_tup_hot_upd AS hot_updates,
    ROUND(s.n_tup_hot_upd * 100.0 / NULLIF(s.n_tup_upd, 0), 2) AS hot_update_ratio,
    s.n_tup_ins AS inserts,
    s.n_tup_del AS deletes,
    COALESCE((regexp_match(c.reloptions::text, 'fillfactor=(\d+)'))[1]::integer, 100) AS current_fillfactor,
    CASE
        WHEN s.n_tup_upd < 1000 THEN '- (too few updates)'
        WHEN s.n_tup_hot_upd * 100.0 / s.n_tup_upd >= 20 THEN 'OK'
        WHEN COALESCE((regexp_match(c.reloptions::text, 'fillfactor=(\d+)'))[1]::integer, 100) = 100
            THEN 'candidate: lower fillfactor'
        ELSE 'low HOT despite fillfactor - check indexed-column updates'
    END AS hot_diagnosis
FROM
    pg_stat_user_tables s
    JOIN pg_class c ON s.relid = c.oid
WHERE
    s.n_tup_upd > 0
ORDER BY
    s.n_tup_upd DESC
LIMIT 50;
