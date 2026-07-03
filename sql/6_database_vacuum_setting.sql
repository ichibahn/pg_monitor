\pset format wrapped
SELECT datname, 
       current_setting('autovacuum_freeze_max_age') AS Autovacuum_Max_Age_Setting, 
       age(datfrozenxid),
       round(100 * (age(datfrozenxid)::numeric / current_setting('autovacuum_freeze_max_age')::numeric), 2) AS EagerMode_Autovacuum_Probability
FROM pg_database;
