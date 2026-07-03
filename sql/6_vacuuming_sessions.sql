\pset format wrapped
SELECT
 datname,
 usename,
 pid,
 CURRENT_TIMESTAMP - xact_start AS xact_runtime,
 query
FROM
 pg_stat_activity
WHERE
upper(query) NOT LIKE '%PG_CLASS%'
AND upper(query) NOT LIKE '%PG_STAT_PROGRESS_VACUUM%'
AND upper(query) LIKE '%VACUUM%'
AND pid != pg_backend_pid()
ORDER BY
 xact_start desc;
