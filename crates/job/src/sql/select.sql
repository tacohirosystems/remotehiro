SELECT
  j.*,
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
      'min_salary', j.min_salary,
      'max_salary', j.max_salary,
      'min_salary_formatted', j.min_salary_formatted,
      'max_salary_formatted', j.max_salary_formatted,
      -- 'min_salary_eur', jls_alt.min_salary_eur,
      -- 'max_salary_eur', jls_alt.max_salary_eur,
      -- 'min_salary_usd', jls_alt.min_salary_usd,
      -- 'max_salary_usd', jls_alt.max_salary_usd,
      -- 'min_salary_jpy', jls_alt.min_salary_jpy,
      -- 'max_salary_jpy', jls_alt.max_salary_jpy,
      -- 'min_salary_gbp', jls_alt.min_salary_gbp,
      -- 'max_salary_gbp', jls_alt.max_salary_gbp,
      -- 'min_salary_aud', jls_alt.min_salary_aud,
      -- 'max_salary_aud', jls_alt.max_salary_aud,
      -- 'min_salary_cad', jls_alt.min_salary_cad,
      -- 'max_salary_cad', jls_alt.max_salary_cad,
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
        aco.emoji || ' ' || aco.name,
        abr.emoji || ' ' || abr.iso2,
        asr.name,
        ar.name
      )
      ORDER BY aco.name, ar.name
    ) FILTER (WHERE j.applicant_region_id IS NOT NULL),
    json_group_array(
      DISTINCT
      coalesce(jco.emoji || ' ' || jco.name, jsr.name, jr.name)
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
FROM enriched_jobs AS j
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
WHERE
  ((?1 ->> 'job_id') IS NULL OR j.job_id = (?1 ->> 'job_id'))
  AND (
    (?1 ->> 'query') IS NULL OR j.position LIKE '%' || (?1 ->> 'query') || '%'
  )
  AND (
    ?1 ->> 'categories' IS NULL OR EXISTS (
      SELECT 1
      FROM json_each(?1 ->> 'categories') c
      WHERE c.value = j.category_name
    )
  )
  AND (
    ?1 ->> 'tags' IS NULL
    OR json_array_intersect(?1 ->> 'tags', coalesce(jt.tags, '[]'))
  )
  AND (
    ?1 ->> 'min_salary' IS NULL
    OR (
      SELECT 1
      FROM warehouse.jobs_location_salaries_in_alt_currencies AS alt_currencies
      WHERE
        alt_currencies.job_id = j.job_id
        AND CASE ?1 ->> 'currency'
          WHEN 'JPY'
            THEN
              alt_currencies.min_salary_jpy >= (?1 ->> 'min_salary')
              OR alt_currencies.max_salary_jpy >= (?1 ->> 'min_salary')
          WHEN 'USD'
            THEN
              alt_currencies.min_salary_usd >= (?1 ->> 'min_salary')
              OR alt_currencies.max_salary_usd >= (?1 ->> 'min_salary')
          WHEN 'GBP'
            THEN
              alt_currencies.min_salary_gbp >= (?1 ->> 'min_salary')
              OR alt_currencies.max_salary_gbp >= (?1 ->> 'min_salary')
          WHEN 'CAD'
            THEN
              alt_currencies.min_salary_cad >= (?1 ->> 'min_salary')
              OR alt_currencies.max_salary_cad >= (?1 ->> 'min_salary')
          WHEN 'AUD'
            THEN
              alt_currencies.min_salary_aud >= (?1 ->> 'min_salary')
              OR alt_currencies.max_salary_aud >= (?1 ->> 'min_salary')
          ELSE
            alt_currencies.min_salary_eur >= (?1 ->> 'min_salary')
            OR alt_currencies.max_salary_eur >= (?1 ->> 'min_salary')
        END
    )
  )
  AND j.deleted_at IS NULL
GROUP BY j.job_id
HAVING
  EXISTS (
    SELECT 1
    FROM
      json_each(coalesce(nullif(onsite_locations, '[]'), '[null]')) AS jl,
      json_each(coalesce(nullif(applicant_locations, '[]'), '[null]')) AS al,
      json_each(coalesce(?1 ->> 'regions', '[null]')) AS filter_region_names,
      json_each(coalesce(?1 ->> 'subregions', '[null]')),
      json_each(coalesce(?1 ->> 'countries_iso2', '[null]'))
        AS filter_country_iso2
    LEFT JOIN countries AS country_filters
      ON filter_country_iso2.value = country_filters.iso2
    WHERE
      CASE
        WHEN filter_region_names.value IS NOT NULL AND NOT is_worldwide
          THEN
            json_extract(jl.value, '$.region_name') = filter_region_names.value
            OR json_extract(al.value, '$.region_name')
            = filter_region_names.value
        ELSE TRUE
      END
      AND CASE
        WHEN filter_country_iso2.value IS NOT NULL AND NOT is_worldwide
          THEN
            json_extract(jl.value, '$.country_iso2') = filter_country_iso2.value
            OR CASE
              WHEN json_extract(al.value, '$.country_id') IS NOT NULL
                THEN
                  json_extract(al.value, '$.country_iso2')
                  = filter_country_iso2.value
              WHEN json_extract(al.value, '$.subregion_id') IS NOT NULL
                THEN
                  json_extract(al.value, '$.subregion_id')
                  = country_filters.subregion_id
              WHEN json_extract(al.value, '$.business_region_id') IS NOT NULL
                THEN
                  json_extract(al.value, '$.business_region_id')
                  = country_filters.business_region_id
              WHEN json_extract(al.value, '$.region_id') IS NOT NULL
                THEN
                  json_extract(al.value, '$.region_id')
                  = country_filters.region_id
              ELSE FALSE
            END
        ELSE TRUE
      END
  )
ORDER BY
  j.addon_pinned_until IS NOT NULL DESC,
  coalesce(j.bumped_at, j.created_at) DESC;
