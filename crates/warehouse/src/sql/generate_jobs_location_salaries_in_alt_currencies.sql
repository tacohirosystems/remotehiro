INSERT INTO jobs_location_salaries_in_alt_currencies(
  job_id,
  job_location_salary_id,
  date,
  min_salary_eur,
  max_salary_eur,
  min_salary_jpy,
  max_salary_jpy,
  min_salary_usd,
  max_salary_usd,
  min_salary_gbp,
  max_salary_gbp,
  min_salary_aud,
  max_salary_aud,
  min_salary_cad,
  max_salary_cad
)
SELECT
  jls.job_id,
  jls.job_location_salary_id,
  ler.Date AS date,

  -- To EUR
  cast(CASE c.code
    WHEN 'EUR' THEN jls.min_salary
    WHEN 'JPY' THEN jls.min_salary / ler.JPY
    WHEN 'USD' THEN jls.min_salary / ler.USD
    WHEN 'GBP' THEN jls.min_salary / ler.GBP
    WHEN 'AUD' THEN jls.min_salary / ler.AUD
    WHEN 'CAD' THEN jls.min_salary / ler.CAD
  END AS INTEGER) AS min_salary_eur,
  cast(CASE c.code
    WHEN 'EUR' THEN jls.max_salary
    WHEN 'JPY' THEN jls.max_salary / ler.JPY
    WHEN 'USD' THEN jls.max_salary / ler.USD
    WHEN 'GBP' THEN jls.max_salary / ler.GBP
    WHEN 'AUD' THEN jls.max_salary / ler.AUD
    WHEN 'CAD' THEN jls.max_salary / ler.CAD
  END AS INTEGER) AS max_salary_eur,

  -- To JPY
  cast(CASE c.code
    WHEN 'EUR' THEN jls.min_salary * ler.JPY
    WHEN 'JPY' THEN jls.min_salary
    WHEN 'USD' THEN (jls.min_salary / ler.USD) * ler.JPY
    WHEN 'GBP' THEN (jls.min_salary / ler.GBP) * ler.GBP
    WHEN 'AUD' THEN (jls.min_salary / ler.AUD) * ler.AUD
    WHEN 'CAD' THEN (jls.min_salary / ler.CAD) * ler.CAD
  END AS INTEGER) AS min_salary_jpy,
  cast(CASE c.code
    WHEN 'EUR' THEN jls.max_salary * ler.JPY
    WHEN 'JPY' THEN jls.max_salary
    WHEN 'USD' THEN (jls.max_salary / ler.USD) * ler.JPY
    WHEN 'GBP' THEN (jls.max_salary / ler.GBP) * ler.JPY
    WHEN 'AUD' THEN (jls.max_salary / ler.AUD) * ler.JPY
    WHEN 'CAD' THEN (jls.max_salary / ler.CAD) * ler.JPY
  END AS INTEGER) AS max_salary_jpy,

  -- To USD
  cast(CASE c.code
    WHEN 'EUR' THEN jls.min_salary * ler.USD
    WHEN 'JPY' THEN (jls.min_salary / ler.JPY) * ler.USD
    WHEN 'USD' THEN jls.min_salary
    WHEN 'GBP' THEN (jls.min_salary / ler.GBP) * ler.USD
    WHEN 'AUD' THEN (jls.min_salary / ler.AUD) * ler.USD
    WHEN 'CAD' THEN (jls.min_salary / ler.CAD) * ler.USD
  END AS INTEGER) AS min_salary_usd,
  cast(CASE c.code
    WHEN 'EUR' THEN jls.max_salary * ler.USD
    WHEN 'JPY' THEN (jls.max_salary / ler.JPY) * ler.USD
    WHEN 'USD' THEN jls.max_salary
    WHEN 'GBP' THEN (jls.max_salary / ler.GBP) * ler.USD
    WHEN 'AUD' THEN (jls.max_salary / ler.AUD) * ler.USD
    WHEN 'CAD' THEN (jls.max_salary / ler.CAD) * ler.USD
  END AS INTEGER) AS max_salary_usd,

  -- To GBP
  cast(CASE c.code
    WHEN 'EUR' THEN jls.min_salary * ler.GBP
    WHEN 'JPY' THEN (jls.min_salary / ler.JPY) * ler.GBP
    WHEN 'USD' THEN (jls.min_salary / ler.USD) * ler.GBP
    WHEN 'GBP' THEN jls.min_salary
    WHEN 'AUD' THEN (jls.min_salary / ler.AUD) * ler.GBP
    WHEN 'CAD' THEN (jls.min_salary / ler.CAD) * ler.GBP
  END AS INTEGER) AS min_salary_gbp,
  cast(CASE c.code
    WHEN 'EUR' THEN jls.max_salary * ler.GBP
    WHEN 'JPY' THEN (jls.max_salary / ler.JPY) * ler.GBP
    WHEN 'USD' THEN (jls.max_salary / ler.USD) * ler.GBP
    WHEN 'GBP' THEN jls.max_salary
    WHEN 'AUD' THEN (jls.max_salary / ler.AUD) * ler.GBP
    WHEN 'CAD' THEN (jls.max_salary / ler.CAD) * ler.GBP
  END AS INTEGER) AS max_salary_gbp,

  -- To AUD
  cast(CASE c.code
    WHEN 'EUR' THEN jls.min_salary * ler.AUD
    WHEN 'JPY' THEN (jls.min_salary / ler.JPY) * ler.AUD
    WHEN 'USD' THEN (jls.min_salary / ler.USD) * ler.AUD
    WHEN 'GBP' THEN (jls.min_salary / ler.GBP) * ler.AUD
    WHEN 'AUD' THEN (jls.min_salary / ler.AUD) * ler.AUD
    WHEN 'CAD' THEN (jls.min_salary / ler.CAD) * ler.AUD
  END AS INTEGER) AS min_salary_aud,
  cast(CASE c.code
    WHEN 'EUR' THEN jls.max_salary * ler.AUD
    WHEN 'JPY' THEN (jls.max_salary / ler.JPY) * ler.AUD
    WHEN 'USD' THEN (jls.max_salary / ler.USD) * ler.AUD
    WHEN 'GBP' THEN (jls.max_salary / ler.GBP) * ler.AUD
    WHEN 'AUD' THEN (jls.max_salary / ler.AUD) * ler.AUD
    WHEN 'CAD' THEN (jls.max_salary / ler.CAD) * ler.AUD
  END AS INTEGER) AS max_salary_aud,

  -- To CAD
  cast(CASE c.code
    WHEN 'EUR' THEN jls.min_salary * ler.CAD
    WHEN 'JPY' THEN (jls.min_salary / ler.JPY) * ler.CAD
    WHEN 'USD' THEN (jls.min_salary / ler.USD) * ler.CAD
    WHEN 'GBP' THEN (jls.min_salary / ler.GBP) * ler.CAD
    WHEN 'AUD' THEN (jls.min_salary / ler.AUD) * ler.CAD
    WHEN 'CAD' THEN jls.min_salary
  END AS INTEGER) AS min_salary_cad,
  cast(CASE c.code
    WHEN 'EUR' THEN jls.max_salary * ler.CAD
    WHEN 'JPY' THEN (jls.max_salary / ler.JPY) * ler.CAD
    WHEN 'USD' THEN (jls.max_salary / ler.USD) * ler.CAD
    WHEN 'GBP' THEN (jls.max_salary / ler.GBP) * ler.CAD
    WHEN 'AUD' THEN (jls.max_salary / ler.AUD) * ler.CAD
    WHEN 'CAD' THEN jls.max_salary
  END AS INTEGER) AS max_salary_cad
FROM
  remotehiro.jobs_location_salaries jls,
  json_each(coalesce(?1, '[null]')) job_ids,
  (SELECT * FROM currency_exchange.rates ORDER BY Date DESC LIMIT 1) AS ler
LEFT JOIN remotehiro.currencies c
  ON jls.currency_id = c.currency_id
WHERE
  CASE
    WHEN job_ids.value IS NOT NULL THEN jls.job_id = job_ids.value
    ELSE true
  END;
