-- Verify remotehiro-warehouse:20260531135509_add_more_currencies on sqlite

BEGIN;

SELECT
  min_salary_pln, max_salary_pln,
  min_salary_sgd, max_salary_sgd,
  min_salary_inr, max_salary_inr,
  min_salary_mxn, max_salary_mxn,
  min_salary_brl, max_salary_brl,
  min_salary_ils, max_salary_ils,
  min_salary_huf, max_salary_huf,
  min_salary_czk, max_salary_czk,
  min_salary_chf, max_salary_chf,
  min_salary_sek, max_salary_sek
FROM jobs_location_salaries_in_alt_currencies WHERE 0;

ROLLBACK;
