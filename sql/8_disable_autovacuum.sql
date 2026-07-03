SELECT pg_is_in_recovery() AS in_recovery
\gset
\if :in_recovery
\echo 'This server is a standby (read-only). Run this action on the primary.'
\else
ALTER TABLE :FULL_TABLE_NAME SET (autovacuum_enabled = false);

\echo =====================================
\echo  Table Option (Autovacuum Enable)
\echo =====================================
SELECT
    n.nspname AS schema_name,
    c.relname AS table_name,
    c.reloptions
FROM
    pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE
    n.nspname = :'SCHEMA_NAME'
    AND c.relname = :'TB_NAME';
\endif
