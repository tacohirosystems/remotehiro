-- Deploy remotehiro-warehouse:20260510063015_add_index to sqlite

BEGIN IMMEDIATE;

CREATE INDEX idx_warehouse_jobs_location_salaries_in_alt_currencies_job_id_job_location_salary_id
  ON jobs_location_salaries_in_alt_currencies(job_id, job_location_salary_id);

COMMIT;
