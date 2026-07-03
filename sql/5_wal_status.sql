\pset format wrapped
SELECT EXISTS (SELECT 1 FROM pg_settings WHERE name LIKE 'apg%') AS is_aurora
\gset
\if :is_aurora
\echo '[Aurora] WAL segment files do not exist on the instance - Aurora writes log'
\echo 'records directly to the shared storage layer, so pg_ls_waldir() is empty.'
\echo 'For WAL/replication health on Aurora, see menu 71 (Replication Status).'
\else
\echo ==================================
\echo  WAL Directory Summary (total)
\echo ==================================
SELECT count(*) AS total_wal_files,
       pg_size_pretty(sum(size)) AS total_wal_size
FROM pg_ls_waldir();

\echo ==========================================
\echo  Recent WAL Files (latest 50 by mtime)
\echo ==========================================
select * from pg_ls_waldir() order by modification desc limit 50;
\endif
