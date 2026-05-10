use std::{fmt::Display, path::PathBuf};

use crate::repository;
use deadpool_sqlite::InteractError;

#[derive(Debug)]
pub enum RepoError {
    Rusqlite(rusqlite::Error),
    Pool(deadpool_sqlite::PoolError),
    Interact(deadpool_sqlite::InteractError),
    Db(model::error::DbError),
}

impl From<rusqlite::Error> for RepoError {
    fn from(err: rusqlite::Error) -> Self {
        RepoError::Rusqlite(err)
    }
}

impl From<deadpool_sqlite::PoolError> for RepoError {
    fn from(err: deadpool_sqlite::PoolError) -> Self {
        RepoError::Pool(err)
    }
}

impl From<deadpool_sqlite::InteractError> for RepoError {
    fn from(err: deadpool_sqlite::InteractError) -> Self {
        RepoError::Interact(err)
    }
}

impl From<model::error::DbError> for RepoError {
    fn from(err: model::error::DbError) -> Self {
        RepoError::Db(err)
    }
}

impl Display for RepoError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            RepoError::Rusqlite(error) => write!(f, "{}", error),
            RepoError::Pool(pool_error) => write!(f, "{}", pool_error),
            RepoError::Interact(interact_error) => write!(f, "{}", interact_error),
            RepoError::Db(db_error) => write!(f, "{}", db_error),
        }
    }
}

impl std::error::Error for RepoError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        None
    }

    fn cause(&self) -> Option<&dyn std::error::Error> {
        self.source()
    }
}

fn exec_list_jobs<'t>(
    conn: &mut rusqlite::Connection,
    filters: model::job::IndexFilters,
) -> Result<Vec<model::job::Job>, model::error::DbError> {
    let txn = conn.transaction()?;
    let jobs = repository::list(
        &txn,
        model::job::RepoIndexFilters {
            tags: filters.tags,
            employment_types: filters.employment_types,
            query: filters.query,
            min_salary: filters.min_salary,
            regions: filters.regions,
            subregions: filters.subregions,
            countries_iso2: filters.countries,
            categories: filters.categories,
            job_id: None,
            currency: filters.currency,
        },
    )?;
    txn.commit()?;

    Ok(jobs)
}

pub async fn list_jobs(
    db_handle: &su_sqlite::handle::Handle,
    filters: model::job::IndexFilters,
    warehouse_db_path: PathBuf,
) -> Result<Vec<model::job::Job>, RepoError> {
    let conn = db_handle.get_write_conn().await?;

    let result = conn
        .interact(
            move |conn: &mut rusqlite::Connection| -> Result<Vec<model::job::Job>, model::error::DbError> {
                database::json_concat_array(&conn)?;
                database::json_array_intersect(&conn)?;
                database::attach_warehouse_db(&conn, &warehouse_db_path)?;

                let result = exec_list_jobs(conn, filters);
                database::detach_warehouse_db(conn)?;
                result
            },
        )
        .await??;

    Ok(result)
}

fn exec_index_jobs_page<'t>(
    conn: &mut rusqlite::Connection,
    filters: model::job::IndexFilters,
    build_info: model::server::BuildInfo,
) -> Result<model::job::IndexPage, model::error::DbError> {
    let txn = conn.transaction()?;
    let regions = location::repository::list_regions(&txn)?;
    let countries = location::repository::list_countries(&txn)?;
    let categories = category::repository::list_has_jobs(&txn)?;
    let tags = tag::repository::list(&txn)?;
    let employment_types = employment::repository::list_types_has_jobs(&txn)?;
    let figures: Vec<i64> = (10_000..=500_000).step_by(10_000).collect();

    let jobs = repository::list(
        &txn,
        model::job::RepoIndexFilters {
            tags: filters.tags,
            employment_types: filters.employment_types,
            query: filters.query,
            min_salary: filters.min_salary,
            regions: filters.regions,
            subregions: filters.subregions,
            countries_iso2: filters.countries,
            categories: filters.categories,
            job_id: None,
            currency: filters.currency,
        },
    )
    .inspect_err(|err| tracing::error!("failed! {}", err))?;

    txn.commit()?;

    Ok(model::job::IndexPage {
        regions,
        countries,
        categories,
        tags,
        jobs,
        employment_types,
        figures,
        build_info,
        available_currencies: vec![
            model::job::Currency::EUR,
            model::job::Currency::USD,
            model::job::Currency::JPY,
            model::job::Currency::GBP,
            model::job::Currency::AUD,
            model::job::Currency::CAD,
        ],
    })
}

pub async fn index_jobs_page(
    db_handle: &su_sqlite::handle::Handle,
    build_info: model::server::BuildInfo,
    filters: model::job::IndexFilters,
    warehouse_db_path: PathBuf,
) -> Result<model::job::IndexPage, RepoError> {
    let conn = db_handle.get_write_conn().await?;

    let result = conn
        .interact(
            move |conn| -> Result<model::job::IndexPage, model::error::DbError> {
                database::attach_warehouse_db(&conn, &warehouse_db_path)?;
                database::json_concat_array(&conn)?;
                database::json_array_intersect(&conn)?;
                let result = exec_index_jobs_page(conn, filters, build_info);
                database::detach_warehouse_db(conn)?;
                result
            },
        )
        .await??;

    Ok(result)
}

fn exec_get_job_page(
    conn: &mut rusqlite::Connection,
    job_id: model::job::JobId,
    build_info: model::server::BuildInfo,
) -> Result<model::job::ViewPage, model::error::DbError> {
    let txn = conn.transaction()?;
    let job = repository::get(&txn, job_id)?;
    let page = model::job::ViewPage { job, build_info };

    txn.commit()?;

    Ok(page)
}

pub async fn get_job_page(
    db_handle: &su_sqlite::handle::Handle,
    warehouse_db_path: PathBuf,
    build_info: model::server::BuildInfo,
    job_id: model::job::JobId,
) -> Result<model::job::ViewPage, RepoError> {
    let conn = db_handle.get_write_conn().await?;

    let result = conn
        .interact(
            move |conn| -> Result<model::job::ViewPage, model::error::DbError> {
                database::json_concat_array(&conn)?;
                database::json_array_intersect(&conn)?;
                database::attach_warehouse_db(&conn, &warehouse_db_path)?;
                let result = exec_get_job_page(conn, job_id, build_info);
                database::detach_warehouse_db(conn)?;
                result
            },
        )
        .await??;

    Ok(result)
}

#[derive(Debug)]
pub enum InsertJobError {
    Interact(InteractError),
    Pool(deadpool_sqlite::PoolError),
    Transaction(rusqlite::Error),
}

impl From<InteractError> for InsertJobError {
    fn from(value: InteractError) -> Self {
        Self::Interact(value)
    }
}

impl From<deadpool_sqlite::PoolError> for InsertJobError {
    fn from(value: deadpool_sqlite::PoolError) -> Self {
        Self::Pool(value)
    }
}

impl From<rusqlite::Error> for InsertJobError {
    fn from(value: rusqlite::Error) -> Self {
        Self::Transaction(value)
    }
}

impl std::fmt::Display for InsertJobError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            InsertJobError::Interact(interact_error) => write!(f, "{}", interact_error),
            InsertJobError::Pool(pool_error) => write!(f, "{}", pool_error),
            InsertJobError::Transaction(error) => write!(f, "{}", error),
        }
    }
}

pub async fn get_job(
    db_handle: &su_sqlite::handle::Handle,
    warehouse_db_path: PathBuf,
    job_id: model::job::JobId,
) -> Result<model::job::Job, RepoError> {
    let conn = db_handle.get_read_conn().await?;

    let result = conn
        .interact(
            move |conn| -> Result<model::job::Job, model::error::DbError> {
                database::attach_warehouse_db(&conn, &warehouse_db_path)?;
                let txn = conn.transaction()?;
                let result = repository::get(&txn, job_id);
                txn.commit()?;
                database::detach_warehouse_db(conn)?;
                Ok(result?)
            },
        )
        .await??;
    Ok(result)
}
