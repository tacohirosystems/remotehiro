use std::sync::Arc;

use crate::HandlerEnv;
use axum::{
    extract::State,
    http::StatusCode,
    response::{Html, IntoResponse},
};
use axum_extra::{
    extract::{cookie::Cookie, CookieJar, Query},
    TypedHeader,
};
use libhtmx::HxRequest;

#[derive(Debug)]
pub enum IndexError {
    Repo(crate::service::RepoError),
    Template(su_template::RenderTemplateError),
}

impl std::error::Error for IndexError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        None
    }

    fn cause(&self) -> Option<&dyn std::error::Error> {
        self.source()
    }
}

impl From<crate::service::RepoError> for IndexError {
    fn from(value: crate::service::RepoError) -> Self {
        Self::Repo(value)
    }
}

impl From<su_template::RenderTemplateError> for IndexError {
    fn from(value: su_template::RenderTemplateError) -> Self {
        Self::Template(value)
    }
}

impl std::fmt::Display for IndexError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            IndexError::Repo(repo_error) => write!(f, "{}", repo_error),
            IndexError::Template(render_template_error) => write!(f, "{}", render_template_error),
        }
    }
}

impl IntoResponse for IndexError {
    fn into_response(self) -> axum::response::Response {
        tracing::error!("failed to get_index. reason: {:#?}", self);
        (StatusCode::INTERNAL_SERVER_ERROR, "Something went wrong").into_response()
    }
}

pub(crate) async fn run(
    State(env): State<Arc<HandlerEnv>>,
    Query(filters): Query<model::job::IndexFilters>,
    TypedHeader(hx_request): TypedHeader<HxRequest>,
    mut jar: CookieJar,
) -> Result<(CookieJar, Html<String>), IndexError> {
    let total = std::time::Instant::now();
    tracing::info!("Handling request...");
    let query_str = serde_html_form::to_string(filters.clone()).unwrap_or("".to_owned());
    jar = jar.add(Cookie::new("query", query_str));

    let html = if hx_request.0 {
        let t = std::time::Instant::now();
        let jobs = crate::service::list_jobs(
            &env.database,
            filters.clone(),
            env.warehouse_db_path.clone(),
        )
        .await
        .inspect_err(|e| tracing::error!("failed to list jobs. reason: {e}"))?;
        tracing::info!("timing: service::list_jobs = {:?}", t.elapsed());

        let t = std::time::Instant::now();
        let html = crate::view::render_index_partial(&env.template, jobs, filters)?;
        tracing::info!("timing: view::render_index_partial = {:?}", t.elapsed());
        html
    } else {
        let t = std::time::Instant::now();
        let index_page = crate::service::index_jobs_page(
            &env.database,
            env.build_info.clone(),
            filters.clone(),
            env.warehouse_db_path.clone(),
        )
        .await
        .inspect_err(|e| tracing::error!("failed to get job page. reason: {e}"))?;
        tracing::info!("timing: service::index_jobs_page = {:?}", t.elapsed());

        let t = std::time::Instant::now();
        let html = crate::view::render_index(&env.template, index_page, filters)
            .inspect_err(|e| tracing::error!("failed to render job page. reason: {e}"))?;
        tracing::info!("timing: view::render_index = {:?}", t.elapsed());
        html
    };

    tracing::debug!("{:#?}", hx_request);
    tracing::info!("timing: handler total = {:?}", total.elapsed());

    Ok((jar, html))
}
