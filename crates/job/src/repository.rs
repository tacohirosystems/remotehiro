use model::error::DbError;
use rusqlite::Transaction;
use serde_json::json;

pub fn list<'t>(
    txn: &Transaction<'t>,
    filters: model::job::RepoIndexFilters,
) -> Result<Vec<model::job::Job>, DbError> {
    let t_prepare = std::time::Instant::now();
    let mut statement = txn.prepare(crate::sql::SELECT_JOBS_QUERY)?;
    tracing::info!(
        "timing: repository::list prepare = {:?}",
        t_prepare.elapsed()
    );

    tracing::info!("{:#?}", json!(filters));

    let t_query = std::time::Instant::now();
    let rows = statement.query_and_then(rusqlite::params![json!(filters)], |row| {
        model::job::Job::try_from(row)
    })?;
    tracing::info!(
        "timing: repository::list query (pre-collect) = {:?}",
        t_query.elapsed()
    );

    let t_collect = std::time::Instant::now();
    let jobs = rows.collect::<Result<Vec<model::job::Job>, _>>()?;
    tracing::info!(
        "timing: repository::list collect (SQL exec + deserialize {} rows) = {:?}",
        jobs.len(),
        t_collect.elapsed()
    );

    Ok(jobs)
}

pub fn get<'t>(
    txn: &Transaction<'t>,
    job_id: model::job::JobId,
) -> Result<model::job::Job, DbError> {
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
        job_type: None,
        is_delisted: None,
    };

    let mut jobs = statement
        .query_and_then(rusqlite::params![json!(filters)], |row| {
            model::job::Job::try_from(row)
        })?
        .collect::<Result<Vec<model::job::Job>, _>>()
        .inspect_err(|err| tracing::error!("{:#?}", err))?;

    match jobs.len() {
        i if i > 1 => Err(DbError::Rusqlite(
            rusqlite::Error::QueryReturnedMoreThanOneRow,
        )),
        // Negative rows??
        i if i <= 0 => Err(DbError::Rusqlite(rusqlite::Error::QueryReturnedNoRows)),
        _ => Ok(jobs.pop().unwrap()),
    }
}
