\pset format wrapped
WITH activity AS (
    SELECT
        wait_event_type,
        wait_event,
        COUNT(*) AS event_count,
        ARRAY_AGG(
            CASE
                WHEN state = 'active' THEN 'Active: ' || LEFT(query, 50)
                ELSE 'Waiting: ' || LEFT(query, 50)
            END ORDER BY query_start
        ) AS query_array,
        MIN(query_start) AS earliest_query_start,
        MAX(now() - query_start) AS max_duration,
        ARRAY_AGG(pid) AS pids,
        ARRAY_AGG(datname) AS databases,
        ARRAY_AGG(usename) AS users
    FROM
        pg_stat_activity
    WHERE
        state IS NOT NULL
        AND pid != pg_backend_pid()
        AND (wait_event_type IS NOT NULL OR wait_event IS NOT NULL)
    GROUP BY
        wait_event_type, wait_event
    HAVING
        COUNT(*) > 0
)
SELECT
    wait_event_type,
    wait_event,
    event_count,
    (SELECT STRING_AGG(q, '; ') FROM UNNEST(query_array[:5]) AS q) AS queries,
    earliest_query_start,
    max_duration
FROM
    activity
ORDER BY
    event_count DESC, max_duration DESC
LIMIT 10;
