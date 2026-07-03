\pset format wrapped
with db_role as
    (
 select case pg_is_in_recovery()
 when true then 'Standby'
 else 'Primary' end as database_role
    ),
ver as
    (
 select current_setting('server_version') as server_version
    ),
up as
    (
 select date_trunc('second', now() - pg_postmaster_start_time()) as uptime
    ),
tz as
    (
 SELECT current_setting('TIMEZONE') as timezone
    ),
enc as
    (
	SELECT pg_encoding_to_char(encoding) as encoding
		FROM pg_database
	WHERE datname = current_database()
    ),
db_details as
    (
 select datname as name,
     age(datfrozenxid) max_frozen_txn,
     encoding as character_set,
     datctype as locale
 from pg_database
 where datname = current_database()
    )
select name, server_version, uptime, encoding, locale, timezone, database_role, max_frozen_txn as "Maximum Used Transaction IDs"
from db_role, ver, up, tz, enc, db_details;
