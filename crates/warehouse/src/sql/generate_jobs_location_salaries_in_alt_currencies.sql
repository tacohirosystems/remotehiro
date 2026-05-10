INSERT INTO jobs_location_salaries_in_alt_currencies (
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
  ler.date,

  -- To EUR
  cast(CASE c.code
    WHEN 'EUR' THEN jls.min_salary
    WHEN 'JPY' THEN jls.min_salary / ler.jpy
    WHEN 'USD' THEN jls.min_salary / ler.usd
    WHEN 'GBP' THEN jls.min_salary / ler.gbp
    WHEN 'AUD' THEN jls.min_salary / ler.aud
    WHEN 'CAD' THEN jls.min_salary / ler.cad
  END AS INTEGER) AS min_salary_eur,
  cast(CASE c.code
    WHEN 'EUR' THEN jls.max_salary
    WHEN 'JPY' THEN jls.max_salary / ler.jpy
    WHEN 'USD' THEN jls.max_salary / ler.usd
    WHEN 'GBP' THEN jls.max_salary / ler.gbp
    WHEN 'AUD' THEN jls.max_salary / ler.aud
    WHEN 'CAD' THEN jls.max_salary / ler.cad
  END AS INTEGER) AS max_salary_eur,

  -- To JPY
  cast(CASE c.code
    WHEN 'EUR' THEN jls.min_salary * ler.jpy
    WHEN 'JPY' THEN jls.min_salary
    WHEN 'USD' THEN (jls.min_salary / ler.usd) * ler.jpy
    WHEN 'GBP' THEN (jls.min_salary / ler.gbp) * ler.gbp
    WHEN 'AUD' THEN (jls.min_salary / ler.aud) * ler.aud
    WHEN 'CAD' THEN (jls.min_salary / ler.cad) * ler.cad
  END AS INTEGER) AS min_salary_jpy,
  cast(CASE c.code
    WHEN 'EUR' THEN jls.max_salary * ler.jpy
    WHEN 'JPY' THEN jls.max_salary
    WHEN 'USD' THEN (jls.max_salary / ler.usd) * ler.jpy
    WHEN 'GBP' THEN (jls.max_salary / ler.gbp) * ler.jpy
    WHEN 'AUD' THEN (jls.max_salary / ler.aud) * ler.jpy
    WHEN 'CAD' THEN (jls.max_salary / ler.cad) * ler.jpy
  END AS INTEGER) AS max_salary_jpy,

  -- To USD
  cast(CASE c.code
    WHEN 'EUR' THEN jls.min_salary * ler.usd
    WHEN 'JPY' THEN (jls.min_salary / ler.jpy) * ler.usd
    WHEN 'USD' THEN jls.min_salary
    WHEN 'GBP' THEN (jls.min_salary / ler.gbp) * ler.usd
    WHEN 'AUD' THEN (jls.min_salary / ler.aud) * ler.usd
    WHEN 'CAD' THEN (jls.min_salary / ler.cad) * ler.usd
  END AS INTEGER) AS min_salary_usd,
  cast(CASE c.code
    WHEN 'EUR' THEN jls.max_salary * ler.usd
    WHEN 'JPY' THEN (jls.max_salary / ler.jpy) * ler.usd
    WHEN 'USD' THEN jls.max_salary
    WHEN 'GBP' THEN (jls.max_salary / ler.gbp) * ler.usd
    WHEN 'AUD' THEN (jls.max_salary / ler.aud) * ler.usd
    WHEN 'CAD' THEN (jls.max_salary / ler.cad) * ler.usd
  END AS INTEGER) AS max_salary_usd,

  -- To GBP
  cast(CASE c.code
    WHEN 'EUR' THEN jls.min_salary * ler.gbp
    WHEN 'JPY' THEN (jls.min_salary / ler.jpy) * ler.gbp
    WHEN 'USD' THEN (jls.min_salary / ler.usd) * ler.gbp
    WHEN 'GBP' THEN jls.min_salary
    WHEN 'AUD' THEN (jls.min_salary / ler.aud) * ler.gbp
    WHEN 'CAD' THEN (jls.min_salary / ler.cad) * ler.gbp
  END AS INTEGER) AS min_salary_gbp,
  cast(CASE c.code
    WHEN 'EUR' THEN jls.max_salary * ler.gbp
    WHEN 'JPY' THEN (jls.max_salary / ler.jpy) * ler.gbp
    WHEN 'USD' THEN (jls.max_salary / ler.usd) * ler.gbp
    WHEN 'GBP' THEN jls.max_salary
    WHEN 'AUD' THEN (jls.max_salary / ler.aud) * ler.gbp
    WHEN 'CAD' THEN (jls.max_salary / ler.cad) * ler.gbp
  END AS INTEGER) AS max_salary_gbp,

  -- To AUD
  cast(CASE c.code
    WHEN 'EUR' THEN jls.min_salary * ler.aud
    WHEN 'JPY' THEN (jls.min_salary / ler.jpy) * ler.aud
    WHEN 'USD' THEN (jls.min_salary / ler.usd) * ler.aud
    WHEN 'GBP' THEN (jls.min_salary / ler.gbp) * ler.aud
    WHEN 'AUD' THEN (jls.min_salary / ler.aud) * ler.aud
    WHEN 'CAD' THEN (jls.min_salary / ler.cad) * ler.aud
  END AS INTEGER) AS min_salary_aud,
  cast(CASE c.code
    WHEN 'EUR' THEN jls.max_salary * ler.aud
    WHEN 'JPY' THEN (jls.max_salary / ler.jpy) * ler.aud
    WHEN 'USD' THEN (jls.max_salary / ler.usd) * ler.aud
    WHEN 'GBP' THEN (jls.max_salary / ler.gbp) * ler.aud
    WHEN 'AUD' THEN (jls.max_salary / ler.aud) * ler.aud
    WHEN 'CAD' THEN (jls.max_salary / ler.cad) * ler.aud
  END AS INTEGER) AS max_salary_aud,

  -- To CAD
  cast(CASE c.code
    WHEN 'EUR' THEN jls.min_salary * ler.cad
    WHEN 'JPY' THEN (jls.min_salary / ler.jpy) * ler.cad
    WHEN 'USD' THEN (jls.min_salary / ler.usd) * ler.cad
    WHEN 'GBP' THEN (jls.min_salary / ler.gbp) * ler.cad
    WHEN 'AUD' THEN (jls.min_salary / ler.aud) * ler.cad
    WHEN 'CAD' THEN jls.min_salary
  END AS INTEGER) AS min_salary_cad,
  cast(CASE c.code
    WHEN 'EUR' THEN jls.max_salary * ler.cad
    WHEN 'JPY' THEN (jls.max_salary / ler.jpy) * ler.cad
    WHEN 'USD' THEN (jls.max_salary / ler.usd) * ler.cad
    WHEN 'GBP' THEN (jls.max_salary / ler.gbp) * ler.cad
    WHEN 'AUD' THEN (jls.max_salary / ler.aud) * ler.cad
    WHEN 'CAD' THEN jls.max_salary
  END AS INTEGER) AS max_salary_cad
FROM
  remotehiro.jobs_location_salaries AS jls,
  json_each(coalesce(?1, '[null]')) AS job_ids,
  (
    SELECT * FROM currency_exchange.rates
    ORDER BY date DESC LIMIT 1
  ) AS ler
LEFT JOIN remotehiro.currencies AS c
  ON jls.currency_id = c.currency_id
WHERE
  CASE
    WHEN job_ids.value IS NOT NULL THEN jls.job_id = job_ids.value
    ELSE TRUE
  END;
