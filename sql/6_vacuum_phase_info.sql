\pset format wrapped
SELECT phase,
  heap_blks_total,
  heap_blks_scanned,
  heap_blks_vacuumed,
  round(100.0 * heap_blks_scanned / heap_blks_total, 2) as pct_done
FROM pg_stat_progress_vacuum;

