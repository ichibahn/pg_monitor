\pset format wrapped
SELECT n.nspname AS schema_name,
       c.relname AS table_name, 
       c.relfrozenxid AS frozen_xid, 
       age(c.relfrozenxid) AS xid_age,
       current_setting('autovacuum_freeze_max_age')::int AS autovacuum_freeze_max_age,
       CASE
           WHEN age(c.relfrozenxid) >= current_setting('autovacuum_freeze_max_age')::int THEN 'CRIT: xid_age >= freeze_max_age (run VACUUM FREEZE now)'
           WHEN age(c.relfrozenxid) >= current_setting('autovacuum_freeze_max_age')::int / 2 THEN 'WARN: xid_age >= 50% of freeze_max_age (plan a vacuum window)'
           ELSE 'OK: xid_age < 50% of freeze_max_age'
       END AS freeze_status
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'r'
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY age(c.relfrozenxid) DESC
LIMIT 50;
