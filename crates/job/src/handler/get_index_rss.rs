use std::sync::Arc;

use crate::HandlerEnv;
use axum::{
    extract::State,
    http::{HeaderMap, StatusCode},
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
) -> Result<(CookieJar, HeaderMap, String), IndexError> {
    tracing::info!("Handling request...");
    let mut headers = HeaderMap::new();
    let query_str = serde_html_form::to_string(filters.clone()).unwrap_or("".to_owned());
    jar = jar.add(Cookie::new("query", query_str));

    headers.insert(
        axum::http::HeaderName::from_static("content-type"),
        axum::http::HeaderValue::from_static("application/xml"),
    );

    let jobs = crate::service::list_jobs(
        &env.database,
        filters.clone(),
        env.warehouse_db_path.clone(),
    )
    .await?;

    let xml = crate::view::render_index_rss(&env.template,jobs);
    tracing::debug!("{:#?}", hx_request);
    Ok((jar, headers, xml))
}
