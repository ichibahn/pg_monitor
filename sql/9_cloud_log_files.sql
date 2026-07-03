\pset format wrapped
SELECT EXISTS (SELECT 1 FROM pg_settings WHERE name LIKE 'rds.%') AS is_rds_family
\gset
\if :is_rds_family
SELECT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'log_fdw') AS has_log_fdw
\gset
\if :has_log_fdw
\qecho ----------------------------------------------------------------------
\qecho PostgreSQL log files on this RDS/Aurora instance (via log_fdw).
\qecho To read one as a table:
\qecho   SELECT create_foreign_table_for_log_file('my_log','log_server','<file_name>');
\qecho   SELECT * FROM my_log WHERE log_entry LIKE '%ERROR%';
\qecho ----------------------------------------------------------------------
SELECT file_name,
       pg_size_pretty(file_size_bytes) AS file_size
FROM list_postgres_log_files()
ORDER BY file_name DESC
LIMIT 20;
\else
\echo 'log_fdw extension is not installed in THIS database.'
\echo 'Note: extensions are per-database - install it in the database you connect to.'
\echo 'It lets you read RDS/Aurora PostgreSQL log files with SQL (no console needed).'
\echo 'Install (requires rds_superuser):'
\echo '  CREATE EXTENSION log_fdw;'
\echo '  CREATE SERVER log_server FOREIGN DATA WRAPPER log_fdw;'
\endif
\else
\echo 'This item is for Amazon RDS / Aurora PostgreSQL only (log_fdw is an AWS extension).'
\echo 'On self-managed PostgreSQL, read files under the log_directory setting directly,'
\echo 'or use pg_ls_logdir() / pg_read_file() with the pg_monitor role.'
\endif
