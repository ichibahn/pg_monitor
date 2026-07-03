\pset format wrapped
\qecho ----------------------------------------------------------------------
\qecho Lock wait tree based on pg_blocking_pids().
\qecho Rows with empty blocked_by are the root blockers - resolve them first.
\qecho ----------------------------------------------------------------------
SELECT
    a.pid,
    pg_blocking_pids(a.pid) AS blocked_by,
    a.usename,
    a.datname,
    a.state,
    a.wait_event_type,
    a.wait_event,
    now() - a.query_start AS runtime,
    LEFT(a.query, 80) AS query
FROM pg_stat_activity a
WHERE cardinality(pg_blocking_pids(a.pid)) > 0

UNION ALL

SELECT
    a.pid,
    pg_blocking_pids(a.pid) AS blocked_by,
    a.usename,
    a.datname,
    a.state,
    a.wait_event_type,
    a.wait_event,
    now() - a.query_start AS runtime,
    LEFT(a.query, 80) AS query
FROM pg_stat_activity a
WHERE a.pid IN (SELECT unnest(pg_blocking_pids(b.pid)) FROM pg_stat_activity b)
  AND cardinality(pg_blocking_pids(a.pid)) = 0
ORDER BY blocked_by, pid;
