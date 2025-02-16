-- Deploy remotehiro:20260111093206_add_states to sqlite

BEGIN IMMEDIATE;

CREATE INDEX country_region ON states(country_id);

ALTER TABLE states DROP COLUMN longitude;
ALTER TABLE states DROP COLUMN latitude;
ALTER TABLE states DROP COLUMN wikiDataId;
ALTER TABLE states DROP COLUMN population;
ALTER TABLE states DROP COLUMN flag;

COMMIT;
