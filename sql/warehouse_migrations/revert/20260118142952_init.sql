-- Revert remotehiro-warehouse:20260118142952_init from sqlite

BEGIN IMMEDIATE;

DROP TABLE jobs_location_salaries_in_alt_currencies;

COMMIT;
