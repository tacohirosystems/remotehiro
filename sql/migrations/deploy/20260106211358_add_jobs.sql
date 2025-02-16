-- Deploy remotehiro:20250202091140_add_jobs to sqlite

BEGIN IMMEDIATE;
  CREATE TABLE categories
    ( category_id INTEGER PRIMARY KEY AUTOINCREMENT
    , name        TEXT NOT NULL
    ) STRICT;

  CREATE TABLE tags
    ( tag_id INTEGER PRIMARY KEY AUTOINCREMENT
    , name   TEXT NOT NULL
    ) STRICT;

  CREATE TABLE employment_types
    ( employment_type_id INTEGER PRIMARY KEY AUTOINCREMENT
    , name               TEXT NOT NULL
    ) STRICT;

  CREATE TABLE industries
    ( industry_id INTEGER PRIMARY KEY AUTOINCREMENT
    , name        TEXT NOT NULL
    ) STRICT;

  CREATE TABLE companies
    ( company_id     INTEGER PRIMARY KEY AUTOINCREMENT
    , name           TEXT NOT NULL
    , homepage_url   TEXT
    , founded_at     INTEGER
    , employee_count INTEGER
    , industry_id    INTEGER REFERENCES industries(industry_id)
    , created_at     TEXT DEFAULT current_timestamp NOT NULL
    , updated_at     TEXT
    , verified_at    TEXT
    , is_verified    INTEGER GENERATED ALWAYS AS (verified_at IS NOT NULL) STORED
    ) STRICT;

  CREATE TABLE jobs
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

  -- Countries/cities in which employees are permitted to work.
  CREATE TABLE jobs_applicant_locations
    ( job_id     INTEGER
    , region_id  INTEGER NOT NULL
    , subregion_id INTEGER
    , country_id INTEGER
    , city_id    INTEGER
    , FOREIGN KEY(job_id) REFERENCES jobs(job_id)
    , FOREIGN KEY(region_id) REFERENCES regions(region_id)
    , FOREIGN KEY(subregion_id) REFERENCES subregions(subregion_id)
    , FOREIGN KEY(country_id) REFERENCES countries(country_id)
    , FOREIGN KEY(city_id) REFERENCES cities(city_id)
    ) STRICT;

  -- Where the job is physically performed, if any.
  CREATE TABLE jobs_locations
    ( job_id     INTEGER NOT NULL
    , region_id  INTEGER NOT NULL
    , subregion_id INTEGER
    , country_id INTEGER
    , city_id    INTEGER
    , FOREIGN KEY(job_id) REFERENCES jobs(job_id)
    , FOREIGN KEY(job_id) REFERENCES jobs(job_id)
    , FOREIGN KEY(region_id) REFERENCES regions(region_id)
    , FOREIGN KEY(subregion_id) REFERENCES subregions(subregion_id)
    , FOREIGN KEY(country_id) REFERENCES countries(country_id)
    , FOREIGN KEY(city_id) REFERENCES cities(city_id)
    ) STRICT;

  CREATE TABLE jobs_tags
    ( job_id INTEGER NOT NULL
    , tag_id INTEGER NOT NULL
    , FOREIGN KEY(job_id) REFERENCES jobs(job_id)
    , FOREIGN KEY(tag_id) REFERENCES tags(tag_id)
    ) STRICT;

  CREATE UNIQUE INDEX idx_unique_categories_name ON categories(name);
  CREATE UNIQUE INDEX idx_employment_types_name ON employment_types(name);
  CREATE UNIQUE INDEX idx_unique_tags_name ON tags(name);
  CREATE UNIQUE INDEX idx_companies_name ON companies(name);
  CREATE INDEX idx_jobs_tags_job_id ON jobs_tags(job_id);
  CREATE INDEX idx_jobs_tags_tag_id ON jobs_tags(tag_id);
COMMIT;
