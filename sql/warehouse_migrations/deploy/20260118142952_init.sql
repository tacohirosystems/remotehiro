-- Deploy remotehiro-warehouse:20260118142952_init to sqlite

BEGIN IMMEDIATE;

CREATE TABLE jobs_location_salaries_in_alt_currencies(
  job_id INTEGER NOT NULL,
  job_location_salary_id INTEGER NOT NULL,

  date TEXT NOT NULL,

  min_salary_eur INTEGER NOT NULL,
  min_salary_usd INTEGER NOT NULL,
  min_salary_jpy INTEGER NOT NULL,
  min_salary_gbp INTEGER NOT NULL,
  min_salary_aud INTEGER NOT NULL,
  min_salary_cad INTEGER NOT NULL,
  max_salary_eur INTEGER,
  max_salary_usd INTEGER,
  max_salary_jpy INTEGER,
  max_salary_gbp INTEGER,
  max_salary_aud INTEGER,
  max_salary_cad INTEGER
) STRICT;

CREATE INDEX idx_job_location_salary_id ON jobs_location_salaries_in_alt_currencies(job_id, job_location_salary_id, date);

COMMIT;
