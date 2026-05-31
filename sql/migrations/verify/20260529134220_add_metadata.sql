-- Verify remotehiro:20260529134220_add_metadata on sqlite

BEGIN;

  SELECT ats_job_uid FROM jobs WHERE 0;
  SELECT period FROM jobs_location_salaries WHERE 0;

ROLLBACK;
