use rusqlite::Transaction;

pub fn list<'t>(txn: &Transaction<'t>) -> Result<Vec<model::category::Category>, rusqlite::Error> {
    let mut statement = txn.prepare(crate::sql::SELECT_CATEGORY_QUERY)?;

    let categories = statement
        .query_map([], |row| model::category::Category::try_from(row))?
        .collect::<Result<Vec<model::category::Category>, _>>()?;

    Ok(categories)
}

pub fn list_has_jobs<'t>(
    txn: &Transaction<'t>,
) -> Result<Vec<model::category::Category>, rusqlite::Error> {
    let mut statement = txn.prepare(crate::sql::SELECT_CATEGORY_HAS_JOBS_QUERY)?;

    let categories = statement
        .query_map([], |row| model::category::Category::try_from(row))?
        .collect::<Result<Vec<model::category::Category>, _>>()?;

    Ok(categories)
}
