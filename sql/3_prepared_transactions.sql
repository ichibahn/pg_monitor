\pset format wrapped
\qecho ----------------------------------------------------------------------
\qecho Prepared (two-phase commit) transactions left on this server.
\qecho Orphaned prepared transactions hold locks and block VACUUM forever.
\qecho Resolve with: COMMIT PREPARED 'gid' or ROLLBACK PREPARED 'gid'
\qecho ----------------------------------------------------------------------
SELECT
    gid,
    prepared,
    now() - prepared AS prepared_age,
    owner,
    database,
    transaction AS xid,
    age(transaction) AS xid_age
FROM pg_prepared_xacts
ORDER BY prepared;
