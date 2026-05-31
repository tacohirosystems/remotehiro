-- Revert remotehiro:20260529131230_add_tag_score from sqlite

BEGIN IMMEDIATE;

ALTER TABLE jobs_tags DROP COLUMN score;

COMMIT;
