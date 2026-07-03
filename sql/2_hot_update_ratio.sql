\pset format wrapped
SELECT
    s.schemaname,
    s.relname,
    s.n_tup_upd AS total_updates,
    s.n_tup_hot_upd AS hot_updates,
    ROUND(s.n_tup_hot_upd * 100.0 / NULLIF(s.n_tup_upd, 0), 2) AS hot_update_ratio,
    s.n_tup_ins AS inserts,
    s.n_tup_del AS deletes,
    COALESCE(
        (SELECT (regexp_match(c.reloptions::text, 'fillfactor=(\d+)'))[1]::integer),
        100
    ) AS current_fillfactor,
    CASE
        WHEN ROUND(s.n_tup_hot_upd * 100.0 / NULLIF(s.n_tup_upd, 0), 2) < 20 THEN 'Yes'
        ELSE 'No'
    END AS "needs_fillfactor_adjustment( < 20%)"
FROM
    pg_stat_user_tables s
    JOIN pg_class c ON s.relid = c.oid
WHERE
    s.n_tup_upd > 0
ORDER BY
    s.n_tup_upd DESC
LIMIT 50;
