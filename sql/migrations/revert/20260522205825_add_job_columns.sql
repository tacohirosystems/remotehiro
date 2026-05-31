-- Revert remotehiro:20260522205825_add_job_columns from sqlite

BEGIN IMMEDIATE;

ALTER TABLE jobs DROP COLUMN source;
ALTER TABLE jobs DROP COLUMN min_equity;
ALTER TABLE jobs DROP COLUMN max_equity;

COMMIT;
