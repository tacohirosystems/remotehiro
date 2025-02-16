-- Revert remotehiro:20260111084106_job_location_salaries_init from sqlite

BEGIN IMMEDIATE;

DROP TABLE jobs_location_salaries;

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
    jl.city_id AS job_city_id,

    --- Applicant location requirements
    jal.region_id AS applicant_region_id,
    jal.subregion_id AS applicant_subregion_id,
    jal.country_id AS applicant_country_id,
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
    j.min_salary,
    j.max_salary,
    j.min_salary_formatted,
    j.max_salary_formatted,

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
    j.bumped_at
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
    ON j.employment_type_id = et.employment_type_id;

DROP TABLE currencies;

COMMIT;
