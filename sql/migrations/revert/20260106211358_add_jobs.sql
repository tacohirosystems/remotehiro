-- Revert remotehiro:20250202091140_add_jobs from sqlite

BEGIN IMMEDIATE;

  DROP TABLE jobs_locations;
  DROP TABLE jobs_applicant_locations;
  DROP TABLE jobs;
  DROP TABLE jobs_tags;
  DROP TABLE companies;
  DROP TABLE employment_types;
  DROP TABLE industries;
  DROP TABLE tags;
  DROP TABLE categories;

COMMIT;
