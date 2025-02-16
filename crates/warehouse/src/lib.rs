use std::{path::PathBuf, sync::Arc};

use axum::{routing, Router};

pub(crate) mod handler;
pub(crate) mod repository;
pub(crate) mod service;
pub(crate) mod sql;

#[derive(Clone)]
pub struct HandlerEnv {
    pub(crate) warehouse_database: Arc<su_sqlite::handle::Handle>,
    pub(crate) remotehiro_db_path: PathBuf,
    pub(crate) currency_exchange_db_path: PathBuf,
}

impl HandlerEnv {
    pub fn new(
        warehouse_database: Arc<su_sqlite::handle::Handle>,
        remotehiro_db_path: PathBuf,
        currency_exchange_db_path: PathBuf,
    ) -> Self {
        Self {
            warehouse_database,
            remotehiro_db_path,
            currency_exchange_db_path,
        }
    }

    pub fn routes(self) -> Router {
        axum::Router::new()
            .route(
                "/api/warehouse/generate",
                routing::post(handler::post_generate_aggregation::run),
            )
            .with_state(Arc::new(self))
    }
}

impl std::fmt::Debug for HandlerEnv {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_tuple("HandlerEnv")
            // .field(&self.)
            // .field(&self.latitude)
            .finish()
    }
}
