-- Revert remotehiro:20260529132800_add_company_slug from sqlite

BEGIN IMMEDIATE;

  ALTER TABLE companies DROP COLUMN slug;
  ALTER TABLE companies DROP COLUMN ats;
  ALTER TABLE companies DROP COLUMN ats_slug;

COMMIT;
