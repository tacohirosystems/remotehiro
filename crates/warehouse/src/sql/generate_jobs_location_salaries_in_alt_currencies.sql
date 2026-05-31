WITH rates AS (
  SELECT
    date,
    json_object(
      'EUR', 1.0,
      'USD', rates.USD,
      'JPY', rates.JPY,
      'GBP', rates.GBP,
      'AUD', rates.AUD,
      'CAD', rates.CAD
    ) AS json
  FROM currency_exchange.rates rates
  ORDER BY date DESC
  LIMIT 1
), salaries_in_eur AS MATERIALIZED (
  SELECT
    jls.job_id,
    jls.job_location_salary_id,
    rates.date,
    rates.json AS rates_json,
    jls.min_salary / json_extract(rates.json, '$.' || from_currency.code) AS min_salary_eur,
    jls.max_salary / json_extract(rates.json, '$.' || from_currency.code) AS max_salary_eur
  FROM
    remotehiro.jobs_location_salaries AS jls,
    rates,
    json_each(coalesce(?1, '[null]')) AS job_ids
  INNER JOIN remotehiro.currencies AS from_currency
    ON jls.currency_id = from_currency.currency_id
  WHERE
    (job_ids.value IS NULL OR jls.job_id = job_ids.value)
    AND json_extract(rates.json, '$.' || from_currency.code) IS NOT NULL
)
INSERT OR REPLACE INTO jobs_location_salaries_in_alt_currencies (
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
  job_id,
  job_location_salary_id,
  date,

  cast(ceil(min_salary_eur) AS INTEGER),
  cast(ceil(max_salary_eur) AS INTEGER),
  cast(ceil(min_salary_eur * json_extract(rates_json, '$.JPY')) AS INTEGER),
  cast(ceil(max_salary_eur * json_extract(rates_json, '$.JPY')) AS INTEGER),
  cast(ceil(min_salary_eur * json_extract(rates_json, '$.USD')) AS INTEGER),
  cast(ceil(max_salary_eur * json_extract(rates_json, '$.USD')) AS INTEGER),
  cast(ceil(min_salary_eur * json_extract(rates_json, '$.GBP')) AS INTEGER),
  cast(ceil(max_salary_eur * json_extract(rates_json, '$.GBP')) AS INTEGER),
  cast(ceil(min_salary_eur * json_extract(rates_json, '$.AUD')) AS INTEGER),
  cast(ceil(max_salary_eur * json_extract(rates_json, '$.AUD')) AS INTEGER),
  cast(ceil(min_salary_eur * json_extract(rates_json, '$.CAD')) AS INTEGER),
  cast(ceil(max_salary_eur * json_extract(rates_json, '$.CAD')) AS INTEGER)
FROM salaries_in_eur;
