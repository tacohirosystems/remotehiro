-- Revert remotehiro:20260527125157_add_more_job_cols from sqlite

BEGIN IMMEDIATE;

ALTER TABLE jobs DROP COLUMN description_html;
ALTER TABLE jobs DROP COLUMN delisted_at;
ALTER TABLE jobs DROP COLUMN posted_at;
ALTER TABLE jobs DROP COLUMN visa_sponsorship;
ALTER TABLE jobs DROP COLUMN offers_equity;

COMMIT;
