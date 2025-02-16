use std::sync::Arc;

use axum::{
    extract::{Path, State},
    http::{header::InvalidHeaderValue, HeaderMap, HeaderValue, StatusCode},
    response::IntoResponse,
};
use axum_extra::extract::CookieJar;

use crate::HandlerEnv;

#[derive(Debug)]
pub enum GetJobError {
    Id,
    Repo(crate::service::RepoError),
    Template(su_template::RenderTemplateError),
    ETag(InvalidHeaderValue),
}

impl std::error::Error for GetJobError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        None
    }

    fn cause(&self) -> Option<&dyn std::error::Error> {
        self.source()
    }
}

impl From<crate::service::RepoError> for GetJobError {
    fn from(value: crate::service::RepoError) -> Self {
        Self::Repo(value)
    }
}

impl From<su_template::RenderTemplateError> for GetJobError {
    fn from(value: su_template::RenderTemplateError) -> Self {
        Self::Template(value)
    }
}

impl From<InvalidHeaderValue> for GetJobError {
    fn from(value: InvalidHeaderValue) -> Self {
        Self::ETag(value)
    }
}

impl std::fmt::Display for GetJobError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            GetJobError::Id => write!(f, "not a valid job ID"),
            GetJobError::Repo(err) => write!(f, "{}", err),
            GetJobError::Template(err) => write!(f, "{}", err),
            GetJobError::ETag(err) => write!(f, "etag encode error {}", err),
        }
    }
}

impl IntoResponse for GetJobError {
    fn into_response(self) -> axum::response::Response {
        tracing::error!("{}", self);
        "Oh no. something happened.".into_response()
    }
}

pub async fn run(
    State(env): State<Arc<HandlerEnv>>,
    Path(slug): Path<String>,
    req_headers: HeaderMap,
    jar: CookieJar,
) -> Result<impl IntoResponse, GetJobError> {
    tracing::info!("Handling request...");
    let job_id = slug.split('-').collect::<Vec<&str>>();
    let query = jar.get("query");
    let query = query.map(|c| c.value());
    let mut res_headers = HeaderMap::new();

    res_headers.insert(
        "cache-control",
        HeaderValue::from_static("public,max-age=60"),
    );

    let job_id = job_id
        .last()
        .ok_or(GetJobError::Id)?
        .parse::<i64>()
        .map(model::job::JobId)
        .map_err(|_| GetJobError::Id)?;

    let req_etag = req_headers.get("if-none-match");

    if let Some(req_etag) = req_etag {
        let job =
            crate::service::get_job(&env.database, env.warehouse_db_path.clone(), job_id).await?;
        let ts = job.updated_at.unix_timestamp();
        let etag = format!("\"{}\"", ts);

        if *req_etag == etag {
            return Ok((StatusCode::NOT_MODIFIED, res_headers).into_response());
        }
    }

    let page = crate::service::get_job_page(
        &env.database,
        env.warehouse_db_path.clone(),
        env.build_info.clone(),
        job_id,
    )
    .await?;
    let updated_at = page.job.updated_at.unix_timestamp();
    let etag = format!("\"{}\"", updated_at);
    let etag = HeaderValue::from_str(etag.as_ref())?;
    res_headers.insert("etag", etag);

    let html = crate::view::render_view(&env.template, page, query)?;
    Ok((res_headers, html).into_response())
}
