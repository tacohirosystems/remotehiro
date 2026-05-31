-- Verify remotehiro-warehouse:20260510063015_add_index on sqlite

BEGIN;

SELECT 1
FROM sqlite_master
WHERE
  type = 'index'
  AND name = 'idx_warehouse_jobs_location_salaries_in_alt_currencies_job_id_job_location_salary_id';

ROLLBACK;
