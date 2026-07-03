\pset format wrapped
SELECT
    name,
    setting AS current_value,
    boot_val AS default_value,
    short_desc,
	pending_restart
FROM
    pg_settings
WHERE
    setting != boot_val
  OR
    pending_restart = 't'
ORDER BY
    name;
