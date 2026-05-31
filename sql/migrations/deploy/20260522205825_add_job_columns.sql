-- Deploy remotehiro:20260522205825_add_job_columns to sqlite

BEGIN IMMEDIATE;

ALTER TABLE jobs ADD COLUMN source TEXT;
ALTER TABLE jobs ADD COLUMN min_equity INTEGER;
ALTER TABLE jobs ADD COLUMN max_equity INTEGER;

COMMIT;
