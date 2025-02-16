use std::path::Path;

use rusqlite::Transaction;

pub fn list_regions<'t>(
    txn: &Transaction<'t>,
) -> Result<Vec<model::location::Region>, rusqlite::Error> {
    let mut statement = txn.prepare(crate::sql::SELECT_REGIONS_QUERY)?;

    let regions = statement
        .query_map([], |row| model::location::Region::try_from(row))?
        .collect::<Result<Vec<model::location::Region>, _>>()?;

    Ok(regions)
}

pub fn list_countries<'t>(
    txn: &Transaction<'t>,
) -> Result<Vec<model::location::Country>, rusqlite::Error> {
    let mut statement = txn.prepare(crate::sql::SELECT_COUNTRIES_QUERY)?;

    let countries = statement
        .query_map([], |row| model::location::Country::try_from(row))?
        .collect::<Result<Vec<model::location::Country>, _>>()?;

    Ok(countries)
}
