use serde::Deserialize;

#[derive(Clone, Debug, Deserialize)]
#[serde(tag = "name")]
pub enum GenerateAggregation {
    JobsLocationSalariesInAltCurrencies {
        job_ids: Option<Vec<crate::job::JobId>>,
    },
}
