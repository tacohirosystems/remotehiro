use std::{fmt::Display, path::PathBuf};

use crate::repository;

#[derive(Debug)]
pub enum RepoError {
    Db(rusqlite::Error),
    Pool(deadpool_sqlite::PoolError),
    Interact(deadpool_sqlite::InteractError),
}

impl From<rusqlite::Error> for RepoError {
    fn from(value: rusqlite::Error) -> Self {
        RepoError::Db(value)
    }
}

impl From<deadpool_sqlite::PoolError> for RepoError {
    fn from(value: deadpool_sqlite::PoolError) -> Self {
        RepoError::Pool(value)
    }
}

impl From<deadpool_sqlite::InteractError> for RepoError {
    fn from(value: deadpool_sqlite::InteractError) -> Self {
        RepoError::Interact(value)
    }
}

impl Display for RepoError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            RepoError::Db(error) => write!(f, "{}", error),
            RepoError::Pool(pool_error) => write!(f, "{}", pool_error),
            RepoError::Interact(interact_error) => write!(f, "{}", interact_error),
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

pub async fn generate_jobs_location_salaries_in_alt_currencies(
    warehouse_db_handle: &su_sqlite::handle::Handle,
    remotehiro_db_path: PathBuf,
    currency_exchange_db_path: PathBuf,
    job_ids: Option<Vec<model::job::JobId>>,
) -> Result<(), RepoError> {
    let conn = warehouse_db_handle.get_write_conn().await?;
    conn.interact(move |conn| -> Result<(), rusqlite::Error> {
        database::attach_remotehiro_db(&conn, &remotehiro_db_path)?;
        database::attach_currency_exchange_db(&conn, &currency_exchange_db_path)?;
        let txn = conn.transaction()?;
        let result = repository::bulk_delete(&txn, job_ids.clone()).and_then(|_| {
            repository::generate_jobs_location_salaries_in_alt_currencies(&txn, job_ids)
        });
        txn.commit()?;
        database::detach_remotehiro_db(conn)?;
        database::detach_currency_exchange_db(conn)?;
        result
    })
    .await??;
    Ok(())
}
