-- Deploy remotehiro:20260118041617_jobs_add_deleted_at to sqlite

BEGIN IMMEDIATE;

ALTER TABLE jobs ADD COLUMN deleted_at TEXT;

DROP VIEW enriched_jobs;

CREATE VIEW enriched_jobs AS
  SELECT
    -- Basic job details
    j.job_id,
    j.position,
    j.description,
    j.apply_url,
    j.apply_email,
    j.post_url,

    -- Employment type
    j.employment_type_id,
    et.name AS employment_type,

    -- Location requirements

    --- If this is true, then it is assumed that the job is fully remote, and
    --- neither hybrid or on-site.
    is_remote,

    --- Job location requirements
    jl.region_id AS job_region_id,
    jl.subregion_id AS job_subregion_id,
    jl.country_id AS job_country_id,
    jl.state_id AS job_state_id,
    jl.city_id AS job_city_id,

    --- Applicant location requirements
    jal.region_id AS applicant_region_id,
    jal.subregion_id AS applicant_subregion_id,
    jal.country_id AS applicant_country_id,
    jal.state_id AS applicant_state_id,
    jal.city_id AS applicant_city_id,

    -- Job discoverability
    --- Tags
    jt.tag_id,
    t.name AS tag_name,

    --- Categories
    ca.category_id,
    ca.name AS category_name,

    -- Company information
    j.company_id,
    co.name AS company_name,

    -- Salary details
    c.currency_id,
    c.code AS currency_code,
    c.symbol AS currency_symbol,
    jls.region_id AS salary_region_id,
    sr.name AS salary_region_name,
    jls.subregion_id AS salary_subregion_id,
    ssr.name AS salary_subregion_name,
    jls.country_id AS salary_country_id,
    sco.name AS salary_country_name,
    sco.emoji AS salary_country_flag,
    jls.state_id AS salary_state_id,
    sst.name AS salary_state_name,
    jls.city_id AS salary_city_id,
    sci.name AS salary_city_name,
    jls.min_salary,
    jls.max_salary,
    CASE
      WHEN jls.min_salary < 1000 THEN printf('%s%d', c.symbol, jls.min_salary)
      WHEN jls.min_salary < 1000000 THEN
        printf('%s%dK', c.symbol, round(abs(jls.min_salary) / 100, 1) / 10)
      WHEN jls.min_salary < 1000000000 THEN
        printf('%s%dM', c.symbol, round(abs(jls.min_salary) / 100000, 1) / 10)
      ELSE printf('%s%,d', c.symbol, jls.min_salary)
    END AS min_salary_formatted,
    CASE
      WHEN jls.max_salary < 1000 THEN printf('%d', jls.max_salary)
      WHEN jls.max_salary < 1000000 THEN
        printf('%s%dK', c.symbol, round(abs(jls.max_salary) / 100, 1) / 10)
      WHEN jls.max_salary < 1000000000 THEN
        printf('%s%dM', c.symbol, round(abs(jls.max_salary) / 100000, 1) / 10)
      ELSE printf('%s%,d', jls.max_salary)
    END AS max_salary_formatted,
    printf('%s%,d', c.symbol, jls.min_salary) AS min_salary_comma_split_formatted,
    printf('%s%,d', c.symbol, jls.max_salary) AS max_salary_comma_split_formatted,

    -- Add-ons
    j.addon_pinned_until,
    j.addon_basic_highlight,
    substr(
      j.addon_custom_highlight,
      2,
      length(j.addon_custom_highlight)
    ) AS addon_custom_highlight,

    -- Addons: check if the job post is still pinned
    coalesce(
      current_timestamp < j.addon_pinned_until,
      FALSE
    ) AS is_pinned,

    (julianday(current_timestamp) - julianday(j.created_at)) * 86400.00 AS relative_created_at,
    j.created_at,
    j.updated_at,
    j.bumped_at,
    j.deleted_at
  FROM jobs j
  LEFT JOIN jobs_locations jl
    ON j.job_id = jl.job_id
  LEFT JOIN jobs_tags jt
    ON j.job_id = jt.job_id
  LEFT JOIN tags t
    ON jt.tag_id = t.tag_id
  LEFT JOIN jobs_applicant_locations jal
    ON j.job_id = jal.job_id
  LEFT JOIN companies co
    ON j.company_id = co.company_id
  LEFT JOIN categories ca
    ON j.category_id = ca.category_id
  LEFT JOIN employment_types et
    ON j.employment_type_id = et.employment_type_id
  LEFT JOIN jobs_location_salaries jls
    ON j.job_id = jls.job_id
  LEFT JOIN currencies c
    ON jls.currency_id = c.currency_id
  LEFT JOIN regions sr
    ON jls.region_id = sr.region_id
  LEFT JOIN subregions ssr
    ON jls.subregion_id = ssr.subregion_id
  LEFT JOIN countries sco
    ON jls.country_id = sco.country_id
  LEFT JOIN states sst
    ON jls.state_id = sst.state_id
  LEFT JOIN cities sci
    ON jls.city_id = sci.city_id;

COMMIT;
