\pset format wrapped
\pset footer off 
SELECT
    COUNT(*) FILTER (WHERE state = 'active') AS active,
    COUNT(*) FILTER (WHERE state = 'idle') AS idle,
    COUNT(*) FILTER (WHERE state = 'idle in transaction') AS idle_in_transaction,
    COUNT(*) FILTER (WHERE state = 'idle in transaction (aborted)') AS idle_in_transaction_aborted,
    COUNT(*) FILTER (WHERE state = 'fastpath function call') AS fastpath_function_call,
    COUNT(*) FILTER (WHERE state = 'disabled') AS disabled
FROM
    pg_stat_activity
WHERE
    pid != pg_backend_pid()
    AND state IS NOT NULL;
