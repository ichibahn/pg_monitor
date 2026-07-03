\pset format wrapped
\pset footer off
SELECT EXISTS (SELECT 1 FROM pg_settings WHERE name LIKE 'apg%') AS is_aurora
\gset
\if :is_aurora
\qecho ----------------------------------------------------------------------
\qecho [Aurora detected] Readers replicate via shared storage and do NOT
\qecho appear in pg_stat_replication - showing aurora_replica_status() instead.
\qecho - replica_lag_in_msec : how far the reader lags behind the writer
\qecho - durable_lsn         : LSN made durable in the shared storage volume
\qecho ----------------------------------------------------------------------
\x
SELECT server_id,
       CASE WHEN session_id = 'MASTER_SESSION_ID' THEN 'writer' ELSE 'reader' END AS role,
       durable_lsn,
       highest_lsn_rcvd,
       current_read_lsn,
       replica_lag_in_msec,
       cur_replay_latency_in_usec,
       active_txns,
       last_update_timestamp,
       cpu
FROM aurora_replica_status()
ORDER BY session_id = 'MASTER_SESSION_ID' DESC, server_id;
\x
\qecho Note: rows appear in pg_stat_replication only for self-managed WAL
\qecho consumers (logical replication, DMS, ...). Check menu 74 for logical.
\else
\qecho ----------------------------------------------
\qecho WAL Sender State
\qecho ----------------------------------------------
\qecho - startup:  WAL sender is starting up
\qecho - catchup: Standby is catching up with primary
\qecho - streaming: Streaming changes after catch-up
\qecho - backup:  Sending a backup
\qecho - stopping: WAL sender is stopping
\qecho ----------------------------------------------
\x
SELECT pid, usename AS username, application_name, client_addr, backend_start, backend_xmin, state,
       sent_lsn, write_lsn, flush_lsn, replay_lsn,
       write_lag, flush_lag, replay_lag,
       sync_state, reply_time
FROM pg_stat_replication;
\endif
