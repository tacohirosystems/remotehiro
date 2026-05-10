-- Revert remotehiro-warehouse:20260510072553_add_tags_aggregation from sqlite

BEGIN IMMEDIATE;

DROP TABLE jobs_tags;

COMMIT;
