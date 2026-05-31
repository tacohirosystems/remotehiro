-- Verify remotehiro:20260527151000_update_view on sqlite

BEGIN;

SELECT
  description_html,
  posted_at,
  delisted_at,
  visa_sponsorship,
  offers_equity
FROM enriched_jobs
WHERE 0;

ROLLBACK;
