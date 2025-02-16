-- Revert remotehiro:20260123102636_add_business_regions from sqlite

BEGIN IMMEDIATE;

ALTER TABLE countries DROP COLUMN business_region_id;
ALTER TABLE jobs_applicant_locations DROP COLUMN business_region_id;
DROP TABLE business_regions;

COMMIT;
