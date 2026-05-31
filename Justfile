migrations-up:
  sqitch --target remotehiro deploy

migrations-down:
  sqitch --target remotehiro revert

migrations-add CHANGE:
  sqitch add --chdir sql/migrations {{ CHANGE }}

warehouse-generate:
  curl -i --fail -X POST "http://localhost:3000/api/warehouse/generate" \
    -d '[{"name": "JobsLocationSalariesInAltCurrencies"}, {"name": "JobsTags"}]' \
    -H 'Content-Type: application/json'

warehouse-migrations-up:
  sqitch --target remotehiro-warehouse deploy

warehouse-migrations-down:
  sqitch --target remotehiro-warehouse revert

warehouse-migrations-add CHANGE:
  sqitch add --chdir sql/warehouse_migrations {{ CHANGE }}

data-migrations-up:
  sqitch --target remotehiro-data deploy

data-migrations-down:
  sqitch --target remotehiro-data revert

data-migrations-add CHANGE:
  sqitch add --chdir sql/data_migrations {{ CHANGE }}

recreate:
  nix build .#remotehiro-migrator-source
  nix build .#remotehiro-migrator
  nix run .#remotehiro-migrator -- init
  nix run .#remotehiro-migrator -- migrations up
  nix run .#remotehiro-migrator -- data-migrations up
  nix run .#remotehiro-migrator -- warehouse-migrations up

bump-flake-rust-inputs:
  nix flake update nixpkgs crane fenix

bump-flake-misc-inputs:
  nix flake update git-hooks flake-parts advisory-db

watch-assets:
  rm -rf public
  watchexec nix run .#asset-builder

fmt:
  cargo fmt

# Copies the latest countries, and cities data into the respective .db files.
copy-locations DATA_DIR:
  curl https://raw.githubusercontent.com/dr5hn/countries-states-cities-database/refs/heads/master/sqlite/countries.sqlite3 > {{ DATA_DIR }}/countries.db

  curl https://raw.githubusercontent.com/dr5hn/countries-states-cities-database/refs/heads/master/sqlite/regions.sqlite3 > {{ DATA_DIR }}/regions.db
  curl https://raw.githubusercontent.com/dr5hn/countries-states-cities-database/refs/heads/master/sqlite/subregions.sqlite3 > {{ DATA_DIR }}/subregions.db
  curl https://raw.githubusercontent.com/dr5hn/countries-states-cities-database/refs/heads/master/sqlite/states.sqlite3 > {{ DATA_DIR }}/states.db

  curl https://raw.githubusercontent.com/dr5hn/countries-states-cities-database/refs/heads/master/sqlite/cities.sqlite3.gz > {{ DATA_DIR }}/cities.db.gz
  gzip --decompress {{ DATA_DIR }}/cities.db.gz --force

export-locations DATA_DIR:
  sqlite3 regions.db .dump > dump-regions.sql
  sqlite3 subregions.db .dump > dump-subregions.sql
  sqlite3 countries.db .dump > dump-countries.sql
  sqlite3 states.db .dump > dump-states.sql
  sqlite3 cities.db .dump > dump-cities.sql
