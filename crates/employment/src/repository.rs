use rusqlite::Transaction;

pub fn list_types<'t>(
    txn: &Transaction<'t>,
) -> Result<Vec<model::employment::EmploymentType>, rusqlite::Error> {
    let mut statement = txn.prepare(crate::sql::SELECT_EMPLOYMENT_TYPES_QUERY)?;

    let tags = statement
        .query_map([], |row| model::employment::EmploymentType::try_from(row))?
        .collect::<Result<Vec<model::employment::EmploymentType>, _>>()?;

    Ok(tags)
}

pub fn list_types_has_jobs<'t>(
    txn: &Transaction<'t>,
) -> Result<Vec<model::employment::EmploymentType>, rusqlite::Error> {
    let mut statement = txn.prepare(crate::sql::SELECT_EMPLOYMENT_TYPES_HAS_JOBS_QUERY)?;

    let tags = statement
        .query_map([], |row| model::employment::EmploymentType::try_from(row))?
        .collect::<Result<Vec<model::employment::EmploymentType>, _>>()?;

    Ok(tags)
}
