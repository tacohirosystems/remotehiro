-- Deploy remotehiro-warehouse:20260531135509_add_more_currencies to sqlite

BEGIN IMMEDIATE;

DELETE FROM jobs_location_salaries_in_alt_currencies;

ALTER TABLE jobs_location_salaries_in_alt_currencies ADD COLUMN min_salary_pln INTEGER NOT NULL;
ALTER TABLE jobs_location_salaries_in_alt_currencies ADD COLUMN max_salary_pln INTEGER;
ALTER TABLE jobs_location_salaries_in_alt_currencies ADD COLUMN min_salary_sgd INTEGER NOT NULL;
ALTER TABLE jobs_location_salaries_in_alt_currencies ADD COLUMN max_salary_sgd INTEGER;
ALTER TABLE jobs_location_salaries_in_alt_currencies ADD COLUMN min_salary_inr INTEGER NOT NULL;
ALTER TABLE jobs_location_salaries_in_alt_currencies ADD COLUMN max_salary_inr INTEGER;
ALTER TABLE jobs_location_salaries_in_alt_currencies ADD COLUMN min_salary_mxn INTEGER NOT NULL;
ALTER TABLE jobs_location_salaries_in_alt_currencies ADD COLUMN max_salary_mxn INTEGER;
ALTER TABLE jobs_location_salaries_in_alt_currencies ADD COLUMN min_salary_brl INTEGER NOT NULL;
ALTER TABLE jobs_location_salaries_in_alt_currencies ADD COLUMN max_salary_brl INTEGER;
ALTER TABLE jobs_location_salaries_in_alt_currencies ADD COLUMN min_salary_ils INTEGER NOT NULL;
ALTER TABLE jobs_location_salaries_in_alt_currencies ADD COLUMN max_salary_ils INTEGER;
ALTER TABLE jobs_location_salaries_in_alt_currencies ADD COLUMN min_salary_huf INTEGER NOT NULL;
ALTER TABLE jobs_location_salaries_in_alt_currencies ADD COLUMN max_salary_huf INTEGER;
ALTER TABLE jobs_location_salaries_in_alt_currencies ADD COLUMN min_salary_czk INTEGER NOT NULL;
ALTER TABLE jobs_location_salaries_in_alt_currencies ADD COLUMN max_salary_czk INTEGER;
ALTER TABLE jobs_location_salaries_in_alt_currencies ADD COLUMN min_salary_chf INTEGER NOT NULL;
ALTER TABLE jobs_location_salaries_in_alt_currencies ADD COLUMN max_salary_chf INTEGER;
ALTER TABLE jobs_location_salaries_in_alt_currencies ADD COLUMN min_salary_sek INTEGER NOT NULL;
ALTER TABLE jobs_location_salaries_in_alt_currencies ADD COLUMN max_salary_sek INTEGER;

COMMIT;
