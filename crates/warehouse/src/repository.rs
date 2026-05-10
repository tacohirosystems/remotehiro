use rusqlite::Transaction;
use serde_json::json;

pub fn bulk_delete_jobs_location_salaries_in_alt_currencies<'t>(
    txn: &Transaction<'t>,
    job_ids: Option<Vec<model::job::JobId>>,
) -> Result<(), rusqlite::Error> {
    let mut statement =
        txn.prepare(crate::sql::BULK_DELETE_JOBS_LOCATION_SALARIES_IN_ALT_CURRENCIES_QUERY)?;
    statement
        .execute(rusqlite::params![json!(job_ids)])
        .inspect_err(|err| tracing::error!("{:#?}", err))?;

    Ok(())
}

pub fn generate_jobs_location_salaries_in_alt_currencies<'t>(
    txn: &Transaction<'t>,
    job_ids: Option<Vec<model::job::JobId>>,
) -> Result<(), rusqlite::Error> {
    let mut statement =
        txn.prepare(crate::sql::GENERATE_JOBS_LOCATION_SALARIES_IN_ALT_CURRENCIES_QUERY)?;
    statement
        .execute(rusqlite::params![json!(job_ids)])
        .inspect_err(|err| tracing::error!("{:#?}", err))?;

    Ok(())
}

pub fn bulk_delete_jobs_tags<'t>(
    txn: &Transaction<'t>,
    job_ids: Option<Vec<model::job::JobId>>,
) -> Result<(), rusqlite::Error> {
    let mut statement =
        txn.prepare(crate::sql::BULK_DELETE_JOBS_TAGS_QUERY)?;
    statement
        .execute(rusqlite::params![json!(job_ids)])
        .inspect_err(|err| tracing::error!("{:#?}", err))?;

    Ok(())
}

pub fn generate_jobs_tags<'t>(
    txn: &Transaction<'t>,
    job_ids: Option<Vec<model::job::JobId>>,
) -> Result<(), rusqlite::Error> {
    let mut statement =
        txn.prepare(crate::sql::GENERATE_JOBS_TAGS_QUERY)?;
    statement
        .execute(rusqlite::params![json!(job_ids)])
        .inspect_err(|err| tracing::error!("{:#?}", err))?;

    Ok(())
}
