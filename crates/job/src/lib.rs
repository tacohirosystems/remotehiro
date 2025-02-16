use std::{path::PathBuf, sync::Arc};

use axum::{routing, Router};

mod handler;
pub mod repository;
pub mod service;
pub mod sql;
pub(crate) mod view;

#[derive(Clone)]
pub struct HandlerEnv {
    pub(crate) database: Arc<su_sqlite::handle::Handle>,
    pub(crate) currency_exchange_db_path: PathBuf,
    pub(crate) warehouse_db_path: PathBuf,
    pub(crate) template: su_template::Handle,
    pub(crate) build_info: model::server::BuildInfo,
}

impl HandlerEnv {
    pub fn new(
        database: Arc<su_sqlite::handle::Handle>,
        template: su_template::Handle,
        build_info: model::server::BuildInfo,
        currency_exchange_db_path: PathBuf,
        warehouse_db_path: PathBuf,
    ) -> Self {
        Self {
            database,
            template,
            build_info,
            currency_exchange_db_path,
            warehouse_db_path,
        }
    }

    pub fn routes(self) -> Router {
        axum::Router::new()
            .route("/", routing::get(handler::get_index::run))
            .route("/jobs.rss", routing::get(handler::get_index_rss::run))
            .route("/jobs/{slug}", routing::get(handler::get_job::run))
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
