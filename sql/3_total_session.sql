\pset format wrapped
SELECT
    COUNT(*) AS total_sessions,
    (SELECT setting::integer FROM pg_settings WHERE name = 'max_connections') AS max_connections
FROM
    pg_stat_activity;
