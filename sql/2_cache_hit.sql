\pset format wrapped
SELECT datname,
blks_hit AS cache_hits,
blks_read AS cache_misses,
CASE
WHEN blks_read + blks_hit = 0 THEN 0
ELSE ROUND(100.0 * blks_hit / (blks_read + blks_hit), 2)
END AS buffer_cache_hit_ratio
FROM pg_stat_database;

