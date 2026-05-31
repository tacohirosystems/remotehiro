-- Verify remotehiro:20260510062811_add_indices on sqlite

BEGIN;

SELECT 1
FROM sqlite_master
WHERE type = 'index' AND name = 'idx_jobs_locations_job_id';
SELECT 1
FROM sqlite_master
WHERE type = 'index' AND name = 'idx_jobs_applicant_locations_job_id';
SELECT 1
FROM sqlite_master
WHERE type = 'index' AND name = 'idx_jobs_location_salaries_job_id';

ROLLBACK;
