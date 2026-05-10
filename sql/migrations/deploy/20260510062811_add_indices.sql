-- Deploy remotehiro:20260510062811_add_indices to sqlite

BEGIN IMMEDIATE;

CREATE INDEX idx_jobs_locations_job_id ON jobs_locations(job_id);
CREATE INDEX idx_jobs_applicant_locations_job_id ON jobs_applicant_locations(job_id);
CREATE INDEX idx_jobs_location_salaries_job_id ON jobs_location_salaries(job_id);

COMMIT;
