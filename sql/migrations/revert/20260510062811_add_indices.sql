-- Revert remotehiro:20260510062811_add_indices from sqlite

BEGIN IMMEDIATE;

DROP INDEX idx_jobs_locations_job_id;
DROP INDEX idx_jobs_applicant_locations_job_id;
DROP INDEX idx_jobs_location_salaries_job_id;

COMMIT;
