-- Deploy remotehiro:20260527125157_add_more_job_cols to sqlite

BEGIN IMMEDIATE;

ALTER TABLE jobs ADD COLUMN description_html TEXT;
ALTER TABLE jobs ADD COLUMN delisted_at TEXT;
ALTER TABLE jobs ADD COLUMN posted_at TEXT;
ALTER TABLE jobs ADD COLUMN visa_sponsorship INTEGER NOT NULL DEFAULT false;
ALTER TABLE jobs ADD COLUMN offers_equity INTEGER NOT NULL DEFAULT false;

COMMIT;
