-- Revert remotehiro:20260103002459_create_jobs_view from sqlite

BEGIN;

DROP VIEW enriched_jobs;

COMMIT;
