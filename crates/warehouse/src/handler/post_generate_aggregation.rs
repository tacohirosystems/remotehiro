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
    fn fmt(&self, _f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            _ => todo!(),
        }
    }
}

impl IntoResponse for PostGenerateAggregationError {
    fn into_response(self) -> axum::response::Response {
        tracing::error!("{}", self);
        "Oh no. something happened.".into_response()
    }
}

#[axum::debug_handler]
pub async fn run(
    State(env): State<Arc<HandlerEnv>>,
    Json(payload): Json<model::warehouse::GenerateAggregation>,
) -> Result<StatusCode, PostGenerateAggregationError> {
    tracing::info!("Handling request");

    match payload {
        model::warehouse::GenerateAggregation::JobsLocationSalariesInAltCurrencies { job_ids } => {
            tracing::info!("Generating JobsLocationSalariesInAltCurrencies...");
            service::generate_jobs_location_salaries_in_alt_currencies(
                &env.warehouse_database,
                env.remotehiro_db_path.clone(),
                env.currency_exchange_db_path.clone(),
                job_ids,
            )
            .await?;
        }
        model::warehouse::GenerateAggregation::JobsTags { job_ids } => {
            tracing::info!("Generating JobsTags...");
            service::generate_jobs_tags(
                &env.warehouse_database,
                env.remotehiro_db_path.clone(),
                env.currency_exchange_db_path.clone(),
                job_ids,
            )
            .await?;
        },
    }

    Ok(StatusCode::OK)
}
