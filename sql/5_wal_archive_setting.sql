\pset format wrapped
SELECT name, setting, unit, short_desc
FROM pg_settings
WHERE name IN (
'archive_mode',
'archive_command',
'archive_library',
'archive_timeout',
'wal_level',
'wal_buffers',
'wal_keep_size',
'wal_compression',
'checkpoint_timeout',
'max_wal_size',
'min_wal_size')
ORDER BY name;
