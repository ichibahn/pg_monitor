\pset format wrapped
SELECT 
    r.rolname AS user_name,
    d.datname AS database_name,
    ARRAY[
        CASE WHEN has_database_privilege(r.rolname, d.datname, 'CONNECT') THEN 'CONNECT' END,
        CASE WHEN has_database_privilege(r.rolname, d.datname, 'CREATE') THEN 'CREATE' END,
        CASE WHEN has_database_privilege(r.rolname, d.datname, 'TEMPORARY') THEN 'TEMPORARY' END,
        CASE WHEN has_database_privilege(r.rolname, d.datname, 'TEMP') THEN 'TEMP' END
    ] AS database_privileges
FROM 
    pg_roles r
CROSS JOIN 
    pg_database d
WHERE 
    d.datistemplate = false
    AND r.rolcanlogin = true
    AND r.rolname NOT LIKE 'pg_%'
    AND (
        has_database_privilege(r.rolname, d.datname, 'CONNECT') OR 
        has_database_privilege(r.rolname, d.datname, 'CREATE') OR 
        has_database_privilege(r.rolname, d.datname, 'TEMPORARY') OR 
        has_database_privilege(r.rolname, d.datname, 'TEMP')
    )
ORDER BY 
    r.rolname, 
    d.datname;
