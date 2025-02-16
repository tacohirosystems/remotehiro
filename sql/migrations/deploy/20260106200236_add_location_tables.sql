-- Deploy remotehiro:20260106200236_add_regions to sqlite

BEGIN IMMEDIATE;

CREATE TABLE regions (
  region_id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  translations TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL DEFAULT 'CURRENT_TIMESTAMP',
  flag INTEGER NOT NULL DEFAULT '1',
  wiki_data_id TEXT NOT NULL
) STRICT;

CREATE TABLE IF NOT EXISTS subregions (
  subregion_id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  translations TEXT NOT NULL,
  region_id INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL DEFAULT 'CURRENT_TIMESTAMP',
  flag INTEGER NOT NULL DEFAULT '1',
  wiki_data_id TEXT NOT NULL,
  FOREIGN KEY(region_id) REFERENCES regions(region_id)
) STRICT;

CREATE TABLE IF NOT EXISTS countries (
  country_id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  iso3 TEXT NOT NULL CHECK (length(iso3) = 3),
  numeric_code TEXT NOT NULL CHECK (length(numeric_code) = 3),
  iso2 TEXT NOT NULL CHECK (length(iso2) = 2),
  phonecode TEXT NOT NULL,
  capital TEXT NOT NULL,
  currency TEXT NOT NULL,
  currency_name TEXT NOT NULL,
  currency_symbol TEXT NOT NULL,
  tld TEXT NOT NULL,
  native TEXT NOT NULL,
  population INTEGER,
  gdp INTEGER,
  region TEXT,
  region_id INTEGER,
  subregion TEXT,
  subregion_id INTEGER,
  nationality TEXT NOT NULL,
  area_sq_km REAL NOT NULL,
  postal_code_format TEXT,
  postal_code_regex TEXT,
  timezones TEXT NOT NULL,
  translations TEXT NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  emoji TEXT NOT NULL CHECK(length(emoji) <= 191),
  emoji_unicode TEXT NOT NULL CHECK(length(emoji) <= 191),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flag INTEGER NOT NULL DEFAULT '1',
  wiki_data_id TEXT NOT NULL CHECK (length(wiki_data_id) <= 255),
  FOREIGN KEY (region_id) REFERENCES regions(region_id),
  FOREIGN KEY (subregion_id) REFERENCES subregions(subregion_id)
) STRICT;

CREATE TABLE states (
  state_id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL  ,
  country_id INTEGER NOT NULL  ,
  country_code TEXT NOT NULL CHECK(length(country_code) = 2),
  fips_code TEXT CHECK(length(fips_code) <= 255),
  iso2 TEXT CHECK(length(iso2) <= 255),
  iso3166_2 TEXT CHECK(length(iso3166_2) <= 10),
  type TEXT CHECK(length(type) <= 191),
  level INTEGER,
  parent_id INTEGER,
  native TEXT CHECK(length(native) <= 255),
  latitude REAL,
  longitude REAL,
  timezone TEXT NULL CHECK(length(timezone) <= 255),
  translations TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flag INTEGER NOT NULL DEFAULT 1,
  wikiDataId TEXT,
  population TEXT,
  FOREIGN KEY(country_id) REFERENCES countries(country_id),
  FOREIGN KEY(parent_id) REFERENCES countries(id)
);

CREATE TABLE IF NOT EXISTS cities (
  city_id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL  ,
  state_id INTEGER NOT NULL  ,
  state_code TEXT NOT NULL  ,
  country_id INTEGER NOT NULL  ,
  country_code TEXT NOT NULL CHECK (length(country_code) = 2),
  type TEXT,
  level INTEGER,
  parent_id INTEGER,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  native_name TEXT,
  population INTEGER,
  timezone TEXT,
  translations TEXT,
  created_at TEXT NOT NULL DEFAULT '2014-01-01 12:01:01' ,
  updated_at TEXT NOT NULL DEFAULT 'CURRENT_TIMESTAMP' ,
  flag INTEGER NOT NULL DEFAULT '1' ,
  wiki_data_id TEXT
) STRICT;

CREATE INDEX idx_subregion_region_id ON subregions (region_id);
CREATE INDEX idx_country_region_id_subregion_id ON countries (region_id, subregion_id);
CREATE INDEX idx_states_country_id_parent_id ON states (country_id, parent_id);
CREATE INDEX idx_cities_country_id_state_id_parent_id ON cities (country_id, state_id, parent_id);

COMMIT;
