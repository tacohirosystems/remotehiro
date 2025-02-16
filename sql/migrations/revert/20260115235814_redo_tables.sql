-- Revert remotehiro:20260115235814_redo_tables from sqlite

BEGIN IMMEDIATE;

CREATE TABLE temp_jobs
  ( job_id                 INTEGER PRIMARY KEY AUTOINCREMENT
  , company_id             INTEGER NOT NULL
  , employment_type_id     INTEGER NOT NULL
  , category_id            INTEGER NOT NULL
  , is_remote              INTEGER NOT NULL
  , position               TEXT NOT NULL CHECK (length(position) > 0)
  , apply_email            TEXT
  , apply_url              TEXT
  , post_url               TEXT
  , description            TEXT
  , salary_currency_code   TEXT CHECK (length(salary_currency_code) = 3)
  , min_salary             INTEGER NOT NULL
  , min_salary_formatted TEXT NOT NULL GENERATED ALWAYS AS (
    CASE
      WHEN min_salary < 1000 THEN printf('%d', min_salary)
      WHEN min_salary < 1000000 THEN
        printf('%dK', round(abs(min_salary) / 100, 1) / 10)
      WHEN min_salary < 1000000000 THEN
        printf('%dM', round(abs(min_salary) / 100000, 1) / 10)
      ELSE printf('%,d', min_salary)
    END
  )
  , max_salary             INTEGER NOT NULL
  , max_salary_formatted TEXT NOT NULL GENERATED ALWAYS AS (
    CASE
      WHEN max_salary < 1000 THEN printf('%d', max_salary)
      WHEN
        max_salary < 1000000
        THEN printf('%dK', round(abs(max_salary) / 100, 1) / 10)
      WHEN
        max_salary < 1000000000
        THEN printf('%dM', round(abs(max_salary) / 100000, 1) / 10)
      ELSE printf('%,d', max_salary)
    END
  ) STORED
  , logo_url               TEXT NOT NULL
  , addon_pinned_until     TEXT
  , addon_basic_highlight  INTEGER NOT NULL DEFAULT false
  , addon_custom_highlight TEXT
  , addon_logo             INTEGER
  , created_at             TEXT DEFAULT current_timestamp NOT NULL
  , updated_at             TEXT DEFAULT current_timestamp NOT NULL
  , bumped_at              TEXT
  , verified_at            TEXT
  , CHECK (
      NOT (
        addon_basic_highlight = true AND
        addon_custom_highlight IS NOT NULL
      )
  )
  , CHECK (min_salary < max_salary)

  -- A job posting may have a description, or link to a URL where the company
  -- detailed stuff about the job.
  , CHECK (
    -- Scenario 1: A job may have a description, and an apply URL for the apply
    -- CTA, but not a post URL.
    (description IS NOT NULL AND apply_url IS NOT NULL AND apply_email IS NULL) OR

    -- Scenario 2: A job may have a description, and an apply email for the apply
    -- CTA, but not a post URL nor an apply URL.
    (description IS NOT NULL AND apply_url IS NULL AND apply_email IS NOT NULL) OR

    -- Scenario 3: A job may have a post URL but no description, and apply URL.
    post_url IS NOT NULL
  )

  , FOREIGN KEY(company_id) REFERENCES companies(company_id)
  , FOREIGN KEY(employment_type_id) REFERENCES employment_types(employment_type_id)
  , FOREIGN KEY(category_id) REFERENCES categories(category_id)
  ) STRICT;

CREATE TABLE temp_jobs_applicant_locations
  ( job_id       INTEGER
  , region_id    INTEGER NOT NULL
  , subregion_id INTEGER
  , country_id   INTEGER
  , city_id      INTEGER
  , FOREIGN KEY(job_id) REFERENCES temp_jobs(job_id)
  , FOREIGN KEY(region_id) REFERENCES regions(region_id)
  , FOREIGN KEY(subregion_id) REFERENCES subregions(subregion_id)
  , FOREIGN KEY(country_id) REFERENCES countries(country_id)
  , FOREIGN KEY(city_id) REFERENCES cities(city_id)
  ) STRICT;

CREATE TABLE temp_jobs_location_salaries(
  job_id INTEGER NOT NULL,
  region_id INTEGER,
  subregion_id INTEGER,
  country_id INTEGER,
  city_id INTEGER,
  min_salary INTEGER NOT NULL,
  max_salary INTEGER,
  currency_id INTEGER NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (job_id) REFERENCES temp_jobs(job_id),
  FOREIGN KEY (region_id) REFERENCES regions(region_id),
  FOREIGN KEY (subregion_id) REFERENCES subregions(subregion_id),
  FOREIGN KEY (country_id) REFERENCES countries(country_id),
  FOREIGN KEY (city_id) REFERENCES cities(city_id),
  FOREIGN KEY (currency_id) REFERENCES currencies(currency_id)
) STRICT;

CREATE TABLE temp_jobs_locations
  ( job_id     INTEGER NOT NULL
  , region_id  INTEGER NOT NULL
  , subregion_id INTEGER
  , country_id INTEGER
  , city_id    INTEGER
  , FOREIGN KEY(job_id) REFERENCES temp_jobs(job_id)
  , FOREIGN KEY(region_id) REFERENCES regions(region_id)
  , FOREIGN KEY(subregion_id) REFERENCES subregions(subregion_id)
  , FOREIGN KEY(country_id) REFERENCES countries(country_id)
  , FOREIGN KEY(city_id) REFERENCES cities(city_id)
  ) STRICT;


-- 2. Migrate existing data over to the new tables

-- 2.0: jobs
INSERT INTO temp_jobs (job_id, company_id, employment_type_id, category_id, is_remote, position, apply_email, apply_url, post_url, description, addon_pinned_until, addon_basic_highlight, created_at, updated_at, bumped_at, verified_at, logo_url, min_salary, max_salary)
SELECT job_id, company_id, employment_type_id, category_id, is_remote, position, apply_email, apply_url, post_url, description, addon_pinned_until, addon_basic_highlight, created_at, updated_at, bumped_at, verified_at, '', 0, 1
FROM jobs;

-- 2.1: jobs_applicant_locations
INSERT INTO temp_jobs_applicant_locations(job_id, region_id, subregion_id, country_id, city_id)
SELECT job_id, region_id, subregion_id, country_id, city_id
FROM temp_jobs_applicant_locations;

-- 2.2: jobs_locations
INSERT INTO temp_jobs_locations(job_id, region_id, subregion_id, country_id, city_id)
SELECT job_id, region_id, subregion_id, country_id, city_id
FROM temp_jobs_applicant_locations;

-- 2.3
INSERT INTO temp_jobs_location_salaries(job_id, region_id, subregion_id, country_id, city_id, min_salary, max_salary, currency_id, created_at)
SELECT job_id, region_id, subregion_id, country_id, city_id, min_salary, max_salary, currency_id, created_at
FROM temp_jobs_location_salaries;

DROP TABLE jobs_applicant_locations;
DROP TABLE jobs_locations;
DROP TABLE jobs_location_salaries;
DROP VIEW enriched_jobs;
DROP TABLE jobs;

ALTER TABLE temp_jobs_applicant_locations RENAME TO jobs_applicant_locations;
ALTER TABLE temp_jobs_location_salaries RENAME TO jobs_location_salaries;
ALTER TABLE temp_jobs_locations RENAME TO jobs_locations;
ALTER TABLE temp_jobs RENAME TO jobs;

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
  LEFT JOIN cities sci
    ON jls.city_id = sci.city_id;

COMMIT;
