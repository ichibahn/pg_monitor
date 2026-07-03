SELECT EXISTS (SELECT 1 FROM pg_settings WHERE name LIKE 'apg%') AS is_aurora
\gset
\if :is_aurora
\pset format wrapped
\qecho ----------------------------------------------------------------------
\qecho [Aurora detected] Readers do not use a WAL receiver (storage-level
\qecho replication) - showing aurora_replica_status() instead.
\qecho This instance:
\qecho ----------------------------------------------------------------------
SELECT aurora_db_instance_identifier() AS this_instance,
       CASE WHEN pg_is_in_recovery() THEN 'reader' ELSE 'writer' END AS this_role;
\x
SELECT server_id,
       CASE WHEN session_id = 'MASTER_SESSION_ID' THEN 'writer' ELSE 'reader' END AS role,
       durable_lsn,
       highest_lsn_rcvd,
       current_read_lsn,
       replica_lag_in_msec,
       cur_replay_latency_in_usec,
       last_update_timestamp
FROM aurora_replica_status()
ORDER BY session_id = 'MASTER_SESSION_ID' DESC, server_id;
\x
\else
\x
\pset footer off
\pset recordsep '\n'
\pset tuples_only on
SELECT * FROM pg_stat_wal_receiver;
\endif
