-- Deploy remotehiro:20260529134220_add_metadata to sqlite

BEGIN IMMEDIATE;

  ALTER TABLE jobs ADD COLUMN ats_job_uid TEXT;

  CREATE UNIQUE INDEX idx_jobs_ats_job_uid
    ON jobs(ats_job_uid)
    WHERE ats_job_uid IS NOT NULL;

  ALTER TABLE jobs_location_salaries ADD COLUMN period TEXT
    CHECK (period IN ('year','month','week','day','hour') OR period IS NULL);

COMMIT;
