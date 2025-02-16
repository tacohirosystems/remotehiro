-- Revert remotehiro:20260106200236_add_regions from sqlite

BEGIN IMMEDIATE;

DROP TABLE regions;

COMMIT;
