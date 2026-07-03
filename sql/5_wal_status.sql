\pset format wrapped
SELECT EXISTS (SELECT 1 FROM pg_settings WHERE name LIKE 'apg%') AS is_aurora
\gset
\if :is_aurora
\echo '[Aurora] WAL segment files do not exist on the instance - Aurora writes log'
\echo 'records directly to the shared storage layer, so pg_ls_waldir() is empty.'
\echo 'For WAL/replication health on Aurora, see menu 71 (Replication Status).'
\else
select * from pg_ls_waldir() order by modification desc limit 50;
\endif
