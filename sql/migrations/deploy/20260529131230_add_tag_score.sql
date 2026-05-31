-- Deploy remotehiro:20260529131230_add_tag_score to sqlite

BEGIN IMMEDIATE;

  ALTER TABLE jobs_tags ADD COLUMN score REAL;

COMMIT;
