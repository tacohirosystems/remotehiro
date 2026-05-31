-- Deploy remotehiro:20260529132800_add_company_slug to sqlite

BEGIN IMMEDIATE;

  ALTER TABLE companies ADD COLUMN slug TEXT;
  ALTER TABLE companies ADD COLUMN ats TEXT;
  ALTER TABLE companies ADD COLUMN ats_slug TEXT;

  CREATE UNIQUE INDEX idx_companies_slug ON companies(slug) WHERE slug IS NOT NULL;
  CREATE UNIQUE INDEX idx_companies_ats_ats_slug ON companies(ats, ats_slug) WHERE ats IS NOT NULL AND ats_slug IS NOT NULL;

COMMIT;
