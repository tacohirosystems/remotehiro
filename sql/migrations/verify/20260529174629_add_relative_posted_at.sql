-- Verify remotehiro:20260529174629_add_relative_posted_at on sqlite

BEGIN;

SELECT relative_posted_at FROM enriched_jobs WHERE 0;

ROLLBACK;
