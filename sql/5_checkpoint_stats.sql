\pset format wrapped
\qecho ----------------------------------------------------------------------
\qecho Checkpoint statistics since stats_reset.
\qecho High pct_requested means checkpoints are triggered by WAL volume
\qecho (max_wal_size too small), not by checkpoint_timeout.
\qecho ----------------------------------------------------------------------
SELECT current_setting('server_version_num')::int >= 170000 AS ge17
\gset
\if :ge17
SELECT
    num_timed AS checkpoints_timed,
    num_requested AS checkpoints_requested,
    round(100.0 * num_requested / NULLIF(num_timed + num_requested, 0), 1) AS pct_requested,
    restartpoints_timed,
    restartpoints_req,
    restartpoints_done,
    round(write_time::numeric / 1000, 1) AS write_time_sec,
    round(sync_time::numeric / 1000, 1) AS sync_time_sec,
    buffers_written,
    stats_reset
FROM pg_stat_checkpointer;
\else
SELECT
    checkpoints_timed,
    checkpoints_req AS checkpoints_requested,
    round(100.0 * checkpoints_req / NULLIF(checkpoints_timed + checkpoints_req, 0), 1) AS pct_requested,
    round(checkpoint_write_time::numeric / 1000, 1) AS write_time_sec,
    round(checkpoint_sync_time::numeric / 1000, 1) AS sync_time_sec,
    buffers_checkpoint AS buffers_written,
    buffers_clean AS buffers_bgwriter,
    buffers_backend,
    stats_reset
FROM pg_stat_bgwriter;
\endif
