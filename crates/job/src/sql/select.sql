WITH filtered_jobs AS (
  SELECT j.job_id
  FROM jobs AS j
  WHERE
    j.deleted_at IS NULL
    AND ((?1 ->> 'job_id') IS NULL OR j.job_id = (?1 ->> 'job_id'))
    AND CASE (?1 ->> 'is_delisted')
      WHEN true THEN j.delisted_at IS NOT NULL
      WHEN false THEN j.delisted_at IS NULL
      ELSE true
    END
    AND (
      (?1 ->> 'query') IS NULL
      OR j.position LIKE '%' || (?1 ->> 'query') || '%'
    )
    AND (
      ?1 ->> 'categories' IS NULL OR j.category_id IN (
        SELECT cat.category_id
        FROM categories AS cat
        WHERE cat.name IN (
          SELECT value FROM json_each(?1 ->> 'categories')
        )
      )
    )
    AND (
      ?1 ->> 'tags' IS NULL OR EXISTS (
        SELECT 1
        FROM jobs_tags AS jt
        INNER JOIN tags AS t ON t.tag_id = jt.tag_id
        WHERE
          jt.job_id = j.job_id
          AND t.name IN (
            SELECT value FROM json_each(?1 ->> 'tags')
          )
      )
    )
    AND (
      ?1 ->> 'min_salary' IS NULL OR EXISTS (
        SELECT 1
        FROM warehouse.jobs_location_salaries_in_alt_currencies AS alt
        WHERE
          alt.job_id = j.job_id
          AND CASE ?1 ->> 'currency'
            WHEN 'JPY' THEN
              alt.min_salary_jpy >= (?1 ->> 'min_salary')
              OR alt.max_salary_jpy >= (?1 ->> 'min_salary')
            WHEN 'USD' THEN
              alt.min_salary_usd >= (?1 ->> 'min_salary')
              OR alt.max_salary_usd >= (?1 ->> 'min_salary')
            WHEN 'GBP' THEN
              alt.min_salary_gbp >= (?1 ->> 'min_salary')
              OR alt.max_salary_gbp >= (?1 ->> 'min_salary')
            WHEN 'CAD' THEN
              alt.min_salary_cad >= (?1 ->> 'min_salary')
              OR alt.max_salary_cad >= (?1 ->> 'min_salary')
            WHEN 'AUD' THEN
              alt.min_salary_aud >= (?1 ->> 'min_salary')
              OR alt.max_salary_aud >= (?1 ->> 'min_salary')
            ELSE
              alt.min_salary_eur >= (?1 ->> 'min_salary')
              OR alt.max_salary_eur >= (?1 ->> 'min_salary')
          END
      )
    )
    AND (
      (?1 ->> 'regions' IS NULL AND ?1 ->> 'countries_iso2' IS NULL)
      OR (
        NOT EXISTS (SELECT 1 FROM jobs_locations WHERE job_id = j.job_id)
        AND NOT EXISTS (
          SELECT 1 FROM jobs_applicant_locations WHERE job_id = j.job_id
        )
      )
      OR EXISTS (
        SELECT 1
        FROM jobs_locations AS jjl
        LEFT JOIN regions AS r ON jjl.region_id = r.region_id
        LEFT JOIN countries AS c ON jjl.country_id = c.country_id
        WHERE
          jjl.job_id = j.job_id
          AND (
            ?1 ->> 'regions' IS NULL
            OR r.name IN (SELECT value FROM json_each(?1 ->> 'regions'))
          )
          AND (
            ?1 ->> 'countries_iso2' IS NULL
            OR c.iso2 IN (
              SELECT value FROM json_each(?1 ->> 'countries_iso2')
            )
          )
      )
      OR EXISTS (
        SELECT 1
        FROM jobs_applicant_locations AS jjal
        LEFT JOIN regions AS r ON jjal.region_id = r.region_id
        LEFT JOIN countries AS c ON jjal.country_id = c.country_id
        WHERE
          jjal.job_id = j.job_id
          AND (
            ?1 ->> 'regions' IS NULL
            OR r.name IN (SELECT value FROM json_each(?1 ->> 'regions'))
          )
          AND (
            ?1 ->> 'countries_iso2' IS NULL
            OR EXISTS (
              SELECT 1
              FROM json_each(?1 ->> 'countries_iso2') AS fc
              LEFT JOIN countries AS cf ON cf.iso2 = fc.value
              WHERE
                CASE
                  WHEN jjal.country_id IS NOT NULL THEN c.iso2 = fc.value
                  WHEN jjal.subregion_id IS NOT NULL THEN
                    jjal.subregion_id = cf.subregion_id
                  WHEN jjal.business_region_id IS NOT NULL THEN
                    jjal.business_region_id = cf.business_region_id
                  WHEN jjal.region_id IS NOT NULL THEN
                    jjal.region_id = cf.region_id
                  ELSE FALSE
                END
            )
          )
      )
    )
    AND (
      ?1 ->> 'job_type' IS NULL OR EXISTS (
        SELECT 1
        FROM json_each(?1 ->> 'job_type') AS t
        WHERE
          (t.value = 'remote' AND j.is_remote = true)
          OR (
            t.value = 'hybrid'
            AND j.is_remote = false
            AND EXISTS (
              SELECT 1 FROM jobs_locations WHERE job_id = j.job_id
            )
            AND EXISTS (
              SELECT 1 FROM jobs_applicant_locations WHERE job_id = j.job_id
            )
          )
          OR (
            t.value = 'on-site'
            AND j.is_remote = false
            AND EXISTS (
              SELECT 1 FROM jobs_locations WHERE job_id = j.job_id
            )
            AND NOT EXISTS (
              SELECT 1 FROM jobs_applicant_locations WHERE job_id = j.job_id
            )
          )
      )
    )
)
SELECT
  j.*,

  -- EUR
  min(warehouse.jobs_location_salaries_in_alt_currencies.min_salary_eur) AS min_salary_eur,
  max(warehouse.jobs_location_salaries_in_alt_currencies.max_salary_eur) AS max_salary_eur,
  -- USD
  min(warehouse.jobs_location_salaries_in_alt_currencies.min_salary_usd) AS min_salary_usd,
  max(warehouse.jobs_location_salaries_in_alt_currencies.max_salary_usd) AS max_salary_usd,
  -- JPY
  min(warehouse.jobs_location_salaries_in_alt_currencies.min_salary_jpy) AS min_salary_jpy,
  max(warehouse.jobs_location_salaries_in_alt_currencies.max_salary_jpy) AS max_salary_jpy,
  -- GBP
  min(warehouse.jobs_location_salaries_in_alt_currencies.min_salary_gbp) AS min_salary_gbp,
  max(warehouse.jobs_location_salaries_in_alt_currencies.max_salary_gbp) AS max_salary_gbp,
  -- AUD
  min(warehouse.jobs_location_salaries_in_alt_currencies.min_salary_aud) AS min_salary_aud,
  max(warehouse.jobs_location_salaries_in_alt_currencies.max_salary_aud) AS max_salary_aud,
  -- CAD
  min(warehouse.jobs_location_salaries_in_alt_currencies.min_salary_cad) AS min_salary_cad,
  max(warehouse.jobs_location_salaries_in_alt_currencies.max_salary_cad) AS max_salary_cad,
  json_group_array(
    DISTINCT
    json_object(
      'region_id', j.salary_region_id,
      'region_name', j.salary_region_name,
      'business_region_id', j.salary_business_region_id,
      'business_region_flag', j.salary_business_region_flag,
      'business_region_name', j.salary_business_region_name,
      'subregion_id', j.salary_subregion_id,
      'subregion_name', j.salary_subregion_name,
      'country_id', j.salary_country_id,
      'country_name', j.salary_country_name,
      'country_flag', j.salary_country_flag,
      'state_id', j.salary_state_id,
      'state_name', j.salary_state_name,
      'city_id', j.salary_city_id,
      'city_name', j.salary_city_name,
      'min_salary_eur', warehouse.jobs_location_salaries_in_alt_currencies.min_salary_eur,
      'max_salary_eur', warehouse.jobs_location_salaries_in_alt_currencies.max_salary_eur,
      'min_salary_usd', warehouse.jobs_location_salaries_in_alt_currencies.min_salary_usd,
      'max_salary_usd', warehouse.jobs_location_salaries_in_alt_currencies.max_salary_usd,
      'min_salary_jpy', warehouse.jobs_location_salaries_in_alt_currencies.min_salary_jpy,
      'max_salary_jpy', warehouse.jobs_location_salaries_in_alt_currencies.max_salary_jpy,
      'min_salary_gbp', warehouse.jobs_location_salaries_in_alt_currencies.min_salary_gbp,
      'max_salary_gbp', warehouse.jobs_location_salaries_in_alt_currencies.max_salary_gbp,
      'min_salary_aud', warehouse.jobs_location_salaries_in_alt_currencies.min_salary_aud,
      'max_salary_aud', warehouse.jobs_location_salaries_in_alt_currencies.max_salary_aud,
      'min_salary_cad', warehouse.jobs_location_salaries_in_alt_currencies.min_salary_cad,
      'max_salary_cad', warehouse.jobs_location_salaries_in_alt_currencies.max_salary_cad,
      'currency_code', j.currency_code,
      'currency_symbol', j.currency_symbol
    )
    ORDER BY j.currency_id ASC
  ) AS location_salaries,
  coalesce(jt.tags, '[]') AS tags,
  json_concat_array(
    json_group_array(
      DISTINCT
      coalesce(
        aco.emoji || ' ' || aco.iso2,
        abr.emoji || ' ' || abr.iso2,
        asr.name,
        ar.name
      )
      ORDER BY aco.name, ar.name
    ) FILTER (WHERE j.applicant_region_id IS NOT NULL),
    json_group_array(
      DISTINCT
      coalesce(jco.emoji || ' ' || jco.iso2, jsr.name, jr.name)
      ORDER BY jco.name, jr.name
    ) FILTER (WHERE j.job_region_id IS NOT NULL)
  ) AS locations,
  json_group_array(
    DISTINCT
    json_object(
      'region_id', j.job_region_id,
      'region_name', jr.name,
      'subregion_id', j.job_subregion_id,
      'subregion_name', jsr.name,
      'country_id', j.job_country_id,
      'country_name', jco.name,
      'country_flag', jco.emoji,
      'country_iso2', jco.iso2,
      'state_id', j.job_state_id,
      'state_name', js.name,
      'city_id', j.job_city_id,
      'city_name', jci.name
    )
  ) FILTER (WHERE j.job_region_id IS NOT NULL) AS onsite_locations,
  json_group_array(
    DISTINCT
    json_object(
      'region_id', j.applicant_region_id,
      'region_name', ar.name,
      'business_region_id', j.applicant_business_region_id,
      'business_region_name', abr.name,
      'business_region_iso2', abr.iso2,
      'business_region_flag', abr.emoji,
      'subregion_id', j.applicant_subregion_id,
      'subregion_name', asr.name,
      'country_id', j.applicant_country_id,
      'country_name', aco.name,
      'country_flag', aco.emoji,
      'country_iso2', aco.iso2,
      'state_id', j.applicant_state_id,
      'state_name', ast.name,
      'city_id', j.applicant_city_id,
      'city_name', aci.name
    )
  ) FILTER (WHERE j.applicant_region_id IS NOT NULL) AS applicant_locations,
  j.job_region_id IS NULL AND j.applicant_region_id IS NULL AS is_worldwide
FROM filtered_jobs AS fj
INNER JOIN enriched_jobs AS j ON j.job_id = fj.job_id
LEFT JOIN regions AS jr
  ON j.job_region_id = jr.region_id
LEFT JOIN subregions AS jsr
  ON j.job_subregion_id = jsr.subregion_id
LEFT JOIN countries AS jco
  ON j.job_country_id = jco.country_id
LEFT JOIN states AS js
  ON j.job_state_id = js.state_id
LEFT JOIN cities AS jci
  ON j.job_city_id = jci.city_id
LEFT JOIN regions AS ar
  ON j.applicant_region_id = ar.region_id
LEFT JOIN business_regions AS abr
  ON j.applicant_business_region_id = abr.business_region_id
LEFT JOIN subregions AS asr
  ON j.applicant_subregion_id = asr.subregion_id
LEFT JOIN countries AS aco
  ON j.applicant_country_id = aco.country_id
LEFT JOIN states AS ast
  ON j.applicant_state_id = ast.state_id
LEFT JOIN cities AS aci
  ON j.applicant_city_id = aci.city_id
LEFT JOIN warehouse.jobs_tags AS jt
  ON j.job_id = jt.job_id
LEFT JOIN warehouse.jobs_location_salaries_in_alt_currencies
  ON j.job_location_salary_id
    = warehouse.jobs_location_salaries_in_alt_currencies.job_location_salary_id
GROUP BY j.job_id
ORDER BY
  j.addon_pinned_until IS NOT NULL DESC,
  coalesce(j.bumped_at, j.posted_at) DESC;
