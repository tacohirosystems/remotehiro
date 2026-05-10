-- Revert remotehiro-warehouse:20260510063015_add_index from sqlite

BEGIN IMMEDIATE;

DROP INDEX idx_warehouse_jobs_location_salaries_in_alt_currencies_job_id_job_location_salary_id;

COMMIT;
