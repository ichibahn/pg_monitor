\pset format wrapped
SELECT EXISTS (SELECT 1 FROM pg_settings WHERE name LIKE 'apg%') AS is_aurora
\gset
\if :is_aurora
\qecho ----------------------------------------------------------------------
\qecho Aurora Global Database replication status (cross-region).
\qecho Not part of a Global Database: shows only the local region with
\qecho durability_lag_in_msec = -1 (or 0 rows on some versions).
\qecho ----------------------------------------------------------------------
\echo ================================
\echo  Global DB Status (per region)
\echo ================================
SELECT * FROM aurora_global_db_status();

\echo ===================================
\echo  Global DB Status (per instance)
\echo ===================================
SELECT * FROM aurora_global_db_instance_status();
\else
\echo 'This item requires Amazon Aurora PostgreSQL (not detected on this server).'
\endif
