-- Verify remotehiro-warehouse:20260510072553_add_tags_aggregation on sqlite

BEGIN;

SELECT 1 FROM sqlite_master
WHERE type = 'table' AND name = 'jobs_tags';

ROLLBACK;
