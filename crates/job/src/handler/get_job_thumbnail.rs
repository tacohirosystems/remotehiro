use std::sync::Arc;

use axum::{
    extract::{Path, State},
    http::{header::InvalidHeaderValue, HeaderMap, HeaderValue, StatusCode},
    response::IntoResponse,
};
use axum_extra::extract::CookieJar;

use crate::HandlerEnv;

#[derive(Debug)]
pub enum GetJobThumbnailError {
    Id,
    Repo(crate::service::RepoError),
    Template(su_template::RenderTemplateError),
    ETag(InvalidHeaderValue),
}

impl std::error::Error for GetJobThumbnailError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        None
    }

    fn cause(&self) -> Option<&dyn std::error::Error> {
        self.source()
    }
}

impl From<crate::service::RepoError> for GetJobThumbnailError {
    fn from(value: crate::service::RepoError) -> Self {
        Self::Repo(value)
    }
}

impl From<su_template::RenderTemplateError> for GetJobThumbnailError {
    fn from(value: su_template::RenderTemplateError) -> Self {
        Self::Template(value)
    }
}

impl From<InvalidHeaderValue> for GetJobThumbnailError {
    fn from(value: InvalidHeaderValue) -> Self {
        Self::ETag(value)
    }
}

impl std::fmt::Display for GetJobThumbnailError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            GetJobThumbnailError::Id => write!(f, "not a valid job ID"),
            GetJobThumbnailError::Repo(err) => write!(f, "{}", err),
            GetJobThumbnailError::Template(err) => write!(f, "{}", err),
            GetJobThumbnailError::ETag(err) => write!(f, "etag encode error {}", err),
        }
    }
}

impl IntoResponse for GetJobThumbnailError {
    fn into_response(self) -> axum::response::Response {
        tracing::error!("{}", self);
        "Oh no. something happened.".into_response()
    }
}

pub async fn run(
    State(env): State<Arc<HandlerEnv>>,
    Path(slug): Path<String>,
) -> Result<impl IntoResponse, GetJobThumbnailError> {
    tracing::info!("Handling request...");
    let job_id = slug.split('-').collect::<Vec<&str>>();
    let mut res_headers = HeaderMap::new();

    res_headers.insert("content-type", HeaderValue::from_static("image/png"));

    let job_id = job_id
        .last()
        .ok_or(GetJobThumbnailError::Id)?
        .parse::<i64>()
        .map(model::job::JobId)
        .map_err(|_| GetJobThumbnailError::Id)?;

    let page = crate::service::get_job_page(
        &env.database,
        env.warehouse_db_path.clone(),
        env.build_info.clone(),
        job_id,
    )
    .await?;

    let html = crate::view::render_job_thumbnail(&env.template, page.job).unwrap();
    Ok((res_headers, html).into_response())
}
