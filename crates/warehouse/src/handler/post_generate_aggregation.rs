use std::sync::Arc;

use axum::{extract::State, http::StatusCode, response::IntoResponse, Json};

use crate::{service, HandlerEnv};

#[derive(Debug)]
pub enum PostGenerateAggregationError {
    Repo(crate::service::RepoError),
}

impl From<crate::service::RepoError> for PostGenerateAggregationError {
    fn from(value: crate::service::RepoError) -> Self {
        Self::Repo(value)
    }
}

impl std::fmt::Display for PostGenerateAggregationError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            _ => write!(f, "{self}"),
        }
    }
}

impl IntoResponse for PostGenerateAggregationError {
    fn into_response(self) -> axum::response::Response {
        tracing::error!("{}", self);
        "Oh no. something happened.".into_response()
    }
}

pub async fn run(
    State(env): State<Arc<HandlerEnv>>,
    Json(payload): Json<Vec<model::warehouse::GenerateAggregation>>,
) -> Result<StatusCode, PostGenerateAggregationError> {
    tracing::info!("Handling request");

    for req in payload {
        match req {
            model::warehouse::GenerateAggregation::JobsLocationSalariesInAltCurrencies { job_ids } => {
                tracing::info!("Generating JobsLocationSalariesInAltCurrencies...");
                service::generate_jobs_location_salaries_in_alt_currencies(
                    &env.warehouse_database,
                    env.remotehiro_db_path.clone(),
                    env.currency_exchange_db_path.clone(),
                    job_ids,
                )
                .await
                .inspect_err(|e| tracing::error!("failed to generate job tags. reason: {e}"))?;
            }
            model::warehouse::GenerateAggregation::JobsTags { job_ids } => {
                tracing::info!("Generating JobsTags...");
                service::generate_jobs_tags(
                    &env.warehouse_database,
                    env.remotehiro_db_path.clone(),
                    env.currency_exchange_db_path.clone(),
                    job_ids,
                )
                .await
                .inspect_err(|e| tracing::error!("failed to generate job tags. reason: {e}"))?;
            },
        }
    }

    Ok(StatusCode::OK)
}
