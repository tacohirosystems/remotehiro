-- Verify remotehiro:20260522205825_add_job_columns on sqlite

BEGIN;

SELECT
  source,
  min_equity,
  max_equity
FROM jobs
WHERE 0;

ROLLBACK;
