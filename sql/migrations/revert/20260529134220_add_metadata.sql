-- Revert remotehiro:20260529134220_add_metadata from sqlite

BEGIN IMMEDIATE;

  ALTER TABLE jobs DROP COLUMN ats_job_uid;
  ALTER TABLE jobs_location_salaries DROP COLUMN period;

COMMIT;
