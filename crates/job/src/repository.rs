use rusqlite::Transaction;
use serde_json::json;

pub fn list<'t>(
    txn: &Transaction<'t>,
    filters: model::job::RepoIndexFilters,
) -> Result<Vec<model::job::Job>, rusqlite::Error> {
    let mut statement = txn.prepare(crate::sql::SELECT_JOBS_QUERY)?;

    tracing::info!("{:#?}", json!(filters));

    let jobs = statement
        .query_map(rusqlite::params![json!(filters)], |row| {
            model::job::Job::try_from(row)
        })?
        .collect::<Result<Vec<model::job::Job>, rusqlite::Error>>()?;

    tracing::info!("{:#?}", jobs);

    Ok(jobs)
}

pub fn get<'t>(
    txn: &Transaction<'t>,
    job_id: model::job::JobId,
) -> Result<model::job::Job, rusqlite::Error> {
    let mut statement = txn.prepare(crate::sql::SELECT_JOBS_QUERY)?;
    let filters = model::job::RepoIndexFilters {
        job_id: Some(job_id),
        regions: None,
        subregions: None,
        countries_iso2: None,
        tags: None,
        employment_types: None,
        categories: None,
        query: None,
        min_salary: None,
        currency: None,
    };

    let job = statement
        .query_row(rusqlite::params![json!(filters)], |row| {
            model::job::Job::try_from(row)
        })
        .inspect_err(|err| tracing::error!("{:#?}", err))?;

    Ok(job)
}
