\pset format wrapped
SELECT
    spcname AS tablespace_name,
    pg_size_pretty(pg_tablespace_size(spcname)) AS size,
    CASE
        WHEN spcname = 'pg_default' THEN (SELECT setting || '/base' FROM pg_settings WHERE name = 'data_directory')
        WHEN spcname = 'pg_global' THEN (SELECT setting || '/global' FROM pg_settings WHERE name = 'data_directory')
        ELSE COALESCE(pg_tablespace_location(oid), '')
    END AS location
FROM
    pg_tablespace
ORDER BY
    pg_tablespace_size(spcname) DESC;
