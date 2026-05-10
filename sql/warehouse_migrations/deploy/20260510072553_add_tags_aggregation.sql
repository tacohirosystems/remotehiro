-- Deploy remotehiro-warehouse:20260510072553_add_tags_aggregation to sqlite

BEGIN IMMEDIATE;

CREATE TABLE jobs_tags(
  job_id INTEGER NOT NULL,
  tags TEXT NOT NULL,
  created_at TEXT DEFAULT current_timestamp NOT NULL,
  updated_at TEXT
) STRICT;

CREATE UNIQUE INDEX jobs_tags_job_id ON jobs_tags(job_id);

COMMIT;
