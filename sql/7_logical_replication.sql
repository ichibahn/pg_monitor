\pset format wrapped
\echo ==============================================
\echo  Publications (this server as publisher)
\echo ==============================================
SELECT pubname, puballtables, pubinsert, pubupdate, pubdelete, pubtruncate
FROM pg_publication
ORDER BY pubname;

\echo ==============================================
\echo  Publication Tables
\echo ==============================================
SELECT pubname, schemaname, tablename
FROM pg_publication_tables
ORDER BY pubname, schemaname, tablename
LIMIT 50;

\echo ==============================================
\echo  Subscriptions (this server as subscriber)
\echo ==============================================
SELECT subname, subenabled, subslotname, subpublications
FROM pg_subscription
ORDER BY subname;

\echo ==============================================
\echo  Subscription Worker Status
\echo ==============================================
SELECT subid, subname, pid, received_lsn, latest_end_lsn,
       last_msg_send_time, last_msg_receipt_time, latest_end_time
FROM pg_stat_subscription
ORDER BY subname;
