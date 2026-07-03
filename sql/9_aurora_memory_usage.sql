\pset format wrapped
SELECT EXISTS (SELECT 1 FROM pg_settings WHERE name LIKE 'apg%') AS is_aurora
\gset
\if :is_aurora
\qecho ----------------------------------------------------------------------
\qecho Per-backend memory context usage (Aurora only).
\qecho Use when FreeableMemory drops or you suspect a memory-hungry backend.
\qecho Cross-check the pid with pg_stat_activity (menu 31).
\qecho Note: on old Aurora versions this function may not exist yet.
\qecho ----------------------------------------------------------------------
SELECT pid,
       name AS memory_context,
       pg_size_pretty(allocated::bigint) AS allocated,
       pg_size_pretty(used::bigint) AS used,
       instances
FROM aurora_stat_memctx_usage()
ORDER BY allocated DESC
LIMIT 30;
\else
\echo 'This item requires Amazon Aurora PostgreSQL (not detected on this server).'
\echo 'On vanilla PostgreSQL 14+, pg_backend_memory_contexts shows YOUR session only.'
\endif
