\pset format wrapped
SELECT 
    r.rolname AS user_name,
    n.nspname AS schema_name,
    ARRAY[
        CASE WHEN has_schema_privilege(r.rolname, n.nspname, 'USAGE') THEN 'USAGE' END,
        CASE WHEN has_schema_privilege(r.rolname, n.nspname, 'CREATE') THEN 'CREATE' END
    ] AS schema_privileges
FROM 
    pg_roles r
CROSS JOIN 
    pg_namespace n
WHERE 
    n.nspname NOT IN ('pg_catalog', 'information_schema')
    AND n.nspname NOT LIKE 'pg_%'
    AND r.rolcanlogin = true 
    AND r.rolname NOT LIKE 'pg_%'
    AND (
        has_schema_privilege(r.rolname, n.nspname, 'USAGE') OR 
        has_schema_privilege(r.rolname, n.nspname, 'CREATE')
    )
ORDER BY 
    r.rolname, 
    n.nspname;
