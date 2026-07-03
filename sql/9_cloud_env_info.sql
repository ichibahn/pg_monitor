\pset format wrapped
SELECT EXISTS (SELECT 1 FROM pg_settings WHERE name LIKE 'apg%') AS is_aurora
\gset
SELECT EXISTS (SELECT 1 FROM pg_settings WHERE name LIKE 'rds.%') AS is_rds_family
\gset

\if :is_aurora
\echo '>> Detected environment: Amazon Aurora PostgreSQL'
\echo
\echo ==============================
\echo  Aurora / Engine Version
\echo ==============================
\x on
SELECT aurora_version() AS aurora_version,
       version()        AS engine_version;
\x off

\echo ==========================================
\echo  Connected Instance (writer or reader?)
\echo ==========================================
\x on
SELECT aurora_db_instance_identifier() AS connected_instance,
       CASE WHEN pg_is_in_recovery() THEN 'reader' ELSE 'writer' END AS instance_role;
\x off
\endif

\if :is_rds_family
\if :is_aurora
\else
\echo '>> Detected environment: Amazon RDS for PostgreSQL'
\endif
\echo
\echo ==============================
\echo  Key Cloud Settings
\echo ==============================
\echo '(curated subset - use menu 12 for the full list of modified parameters)'
-- Aurora/RDS expose dozens of rds.*/apg.* GUCs; a full dump does not fit one
-- screen. Show only the settings a DBA usually cares about. Names not present
-- on this engine/version are skipped silently (no error), so this stays clean
-- across RDS and Aurora. Add more names below if you want them surfaced here.
SELECT name, setting, unit
FROM pg_settings
WHERE name IN (
    'rds.force_ssl',
    'rds.logical_replication',
    'rds.rds_superuser_reserved_connections',
    'rds.restrict_password_commands',
    'rds.log_retention_period',
    'rds.enable_plan_management'
)
ORDER BY name;

SELECT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rds_superuser') AS has_rds_su_role
\gset
\if :has_rds_su_role
\echo ==================================
\echo  rds_superuser Membership Check
\echo ==================================
SELECT current_user,
       pg_has_role(current_user, 'rds_superuser', 'member') AS is_rds_superuser;
\endif
\else
\echo 'This item is for Amazon RDS / Aurora PostgreSQL only.'
\echo 'Detected environment: self-managed (vanilla) PostgreSQL - no rds.* settings found.'
\echo 'For instance info on this server, see menu 11 (Cluster/Instance Info).'
\endif
