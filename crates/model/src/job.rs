use std::num::NonZero;

use rusqlite::{
    types::{Null, ToSqlOutput},
    ToSql,
};
use serde::{Deserialize, Serialize};
use time::{Duration, OffsetDateTime};

use crate::{category::Category, employment::EmploymentType, location, server, tag::Tag};

#[derive(Clone, Copy, Debug, Deserialize, Serialize)]
pub struct JobId(pub i64);

#[derive(Debug, Deserialize, Serialize)]
pub struct OnsiteLocation {
    pub region_id: i64,
    pub region_name: String,
    pub subregion_id: i64,
    pub subregion_name: String,
    pub country_id: i64,
    pub country_flag: String,
    pub country_iso2: String,
    pub country_name: String,
    pub state_id: i64,
    pub state_name: String,
    pub city_id: i64,
    pub city_name: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct ApplicantLocation {
    pub region_id: i64,
    pub region_name: String,
    pub business_region_id: Option<i64>,
    pub business_region_flag: Option<String>,
    pub business_region_iso2: Option<String>,
    pub business_region_name: Option<String>,
    pub subregion_id: Option<i64>,
    pub subregion_name: Option<String>,
    pub country_id: Option<i64>,
    pub country_flag: Option<String>,
    pub country_iso2: Option<String>,
    pub country_name: Option<String>,
    pub state_id: Option<i64>,
    pub state_name: Option<String>,
    pub city_id: Option<i64>,
    pub city_name: Option<String>,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct AltCurrencies {
    pub min_salary_eur: i64,
    pub max_salary_eur: Option<i64>,
    pub min_salary_usd: i64,
    pub max_salary_usd: Option<i64>,
    pub min_salary_jpy: i64,
    pub max_salary_jpy: Option<i64>,
    pub min_salary_gbp: i64,
    pub max_salary_gbp: Option<i64>,
    pub min_salary_aud: i64,
    pub max_salary_aud: Option<i64>,
    pub min_salary_cad: i64,
    pub max_salary_cad: Option<i64>,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct LocationSalary {
    pub region_id: Option<location::RegionId>,
    pub region_name: Option<String>,
    pub business_region_name: Option<String>,
    pub business_region_flag: Option<String>,
    pub country_id: Option<location::CountryId>,
    pub country_name: Option<String>,
    pub country_flag: Option<String>,
    pub state_name: Option<String>,
    pub city_name: Option<String>,
    pub currency_code: String,
    pub currency_symbol: String,
    pub min_salary: i64,
    pub max_salary: Option<i64>,
    pub min_salary_formatted: String,
    pub max_salary_formatted: Option<String>,
    // pub min_salary_eur: i64,
    // pub max_salary_eur: Option<i64>,
    // pub min_salary_jpy: i64,
    // pub max_salary_jpy: Option<i64>,
    // pub min_salary_usd: i64,
    // pub max_salary_usd: Option<i64>,
    // pub min_salary_gbp: i64,
    // pub max_salary_gbp: Option<i64>,
    // pub min_salary_aud: i64,
    // pub max_salary_aud: Option<i64>,
    // pub min_salary_cad: i64,
    // pub max_salary_cad: Option<i64>,
}

#[derive(Debug, Serialize)]
pub struct Job {
    pub id: i64,
    pub description: String,
    pub apply_url: Option<String>,
    pub apply_email: Option<String>,
    pub company_id: i64,
    pub company_name: String,
    pub category_name: String,
    pub employment_type: String,
    pub position: String,
    pub onsite_locations: Vec<OnsiteLocation>,
    pub applicant_locations: Vec<ApplicantLocation>,
    pub locations: Vec<String>,
    pub is_worldwide: bool,
    pub location_salaries: Vec<LocationSalary>,
    pub tags: Vec<String>,
    pub addon_pinned_until: Option<OffsetDateTime>,
    pub addon_highlight: AddonHighlight,
    pub is_pinned: bool,
    pub is_remote: bool,
    pub relative_created_at: Duration,
    pub relative_bumped_at: Option<Duration>,
    pub created_at: OffsetDateTime,
    pub updated_at: OffsetDateTime,
    pub bumped_at: Option<OffsetDateTime>,
}

#[derive(Debug, Serialize)]
pub struct IndexPage {
    pub regions: Vec<location::Region>,
    pub countries: Vec<location::Country>,
    pub categories: Vec<Category>,
    pub tags: Vec<Tag>,
    pub jobs: Vec<Job>,
    pub employment_types: Vec<EmploymentType>,
    pub figures: Vec<i64>,
    pub build_info: server::BuildInfo,
    pub available_currencies: Vec<Currency>,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub enum Currency {
    EUR,
    USD,
    JPY,
    GBP,
    AUD,
    CAD,
}

/// User provided params/filters
#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct IndexFilters {
    #[serde(rename = "query")]
    pub query: Option<String>,
    pub min_salary: Option<NonZero<i64>>,
    #[serde(rename = "tag")]
    pub tags: Option<Vec<String>>,
    #[serde(rename = "employment_type")]
    pub employment_types: Option<Vec<String>>,
    #[serde(rename = "region")]
    pub regions: Option<Vec<String>>,
    #[serde(rename = "subregion")]
    pub subregions: Option<Vec<String>>,
    #[serde(rename = "country")]
    pub countries: Option<Vec<String>>,
    #[serde(rename = "category")]
    pub categories: Option<Vec<String>>,
    pub currency: Option<Currency>,
}

#[derive(Debug, Serialize)]
pub struct CreatePage {
    pub regions: Vec<location::Region>,
    pub countries: Vec<location::Country>,
    pub categories: Vec<Category>,
    pub tags: Vec<Tag>,
    pub employment_types: Vec<EmploymentType>,
    pub error: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct ViewPage {
    pub job: Job,
    pub build_info: server::BuildInfo,
}

#[derive(Clone, Copy, Debug, Deserialize, Serialize)]
#[serde(transparent)]
pub struct AddonIncludeLogo(pub bool);

#[derive(Debug, Deserialize, Serialize)]
pub struct AddonDispatchEmail(pub bool);

#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(
    rename_all = "lowercase",
    tag = "addon_highlight",
    content = "addon_highlight_color"
)]
pub enum AddonHighlight {
    // FIXME: The `String` is not used but is needed for deserializing
    Basic(String),
    Custom(String),
    None(String),
}

#[derive(Clone, Copy, Debug, Deserialize, Serialize)]
#[serde(rename_all = "lowercase")]
pub enum AddonPinnedDuration {
    #[serde(rename = "days_30")]
    Days30,
    #[serde(rename = "days_7")]
    Days7,
    #[serde(rename = "days_1")]
    Hours24,
    #[serde(rename = "none")]
    None,
}

#[derive(Debug, Serialize)]
pub struct RepoIndexFilters {
    pub regions: Option<Vec<String>>,
    pub subregions: Option<Vec<String>>,
    pub countries_iso2: Option<Vec<String>>,
    pub tags: Option<Vec<String>>,
    pub employment_types: Option<Vec<String>>,
    pub categories: Option<Vec<String>>,
    pub query: Option<String>,
    pub min_salary: Option<NonZero<i64>>,
    pub job_id: Option<JobId>,
    pub currency: Option<Currency>,
}

impl ToSql for &Currency {
    fn to_sql(&self) -> rusqlite::Result<ToSqlOutput<'_>> {
        let currency = match self {
            Currency::EUR => "EUR",
            Currency::USD => "USD",
            Currency::GBP => "GBP",
            Currency::JPY => "JPY",
            Currency::AUD => "AUD",
            Currency::CAD => "CAD",
        };

        Ok(ToSqlOutput::Borrowed(rusqlite::types::ValueRef::Text(
            currency.as_bytes(),
        )))
    }
}

impl ToSql for JobId {
    fn to_sql(&self) -> rusqlite::Result<ToSqlOutput<'_>> {
        Ok(ToSqlOutput::Owned(rusqlite::types::Value::Integer(self.0)))
    }
}

impl TryFrom<&rusqlite::Row<'_>> for Job {
    type Error = crate::error::DbError;

    fn try_from(row: &rusqlite::Row<'_>) -> Result<Self, Self::Error> {
        // TODO: Remove unwraps for the sake of your sanity!!
        let onsite_locations = serde_json::from_value(row.get("onsite_locations")?)?;
        let applicant_locations = serde_json::from_value(row.get("applicant_locations")?)?;
        let locations = serde_json::from_value(row.get("locations")?)?;
        let location_salaries = serde_json::from_value(row.get("location_salaries")?)?;
        let tags = serde_json::from_value(row.get("tags")?)?;
        let position = row.get("position")?;
        let relative_bumped_at = row.get::<&str, Option<f64>>("relative_bumped_at")?.map(Duration::seconds_f64);
        let addon_pinned_until = row.get::<&str, Option<OffsetDateTime>>("addon_pinned_until")?;
        let addon_basic_highlight = row.get::<&str, bool>("addon_basic_highlight")?;
        let addon_custom_highlight = row.get::<&str, Option<String>>("addon_custom_highlight")?;

        let addon_highlight = match (addon_basic_highlight, addon_custom_highlight) {
            (true, None) => AddonHighlight::Basic("fffdd0".to_owned()),
            (_, Some(hex)) => AddonHighlight::Custom(hex),
            // FIXME: Remove need for value in `None` variant
            (false, None) => AddonHighlight::None("".to_owned()),
        };

        Ok(Job {
            id: row.get("job_id")?,
            description: row.get("description")?,
            apply_url: row.get("apply_url")?,
            apply_email: row.get("apply_email")?,
            company_id: row.get("company_id")?,
            company_name: row.get("company_name")?,
            category_name: row.get("category_name")?,
            employment_type: row.get("employment_type")?,
            position,
            onsite_locations,
            applicant_locations,
            locations,
            is_worldwide: row.get("is_worldwide")?,
            location_salaries,
            tags,
            addon_pinned_until,
            addon_highlight,
            is_pinned: row.get("is_pinned")?,
            is_remote: row.get("is_remote")?,
            relative_created_at: Duration::seconds_f64(row.get("relative_created_at")?),
            relative_bumped_at,
            created_at: row.get("created_at")?,
            updated_at: row.get("updated_at")?,
            bumped_at: row.get("bumped_at")?,
        })
    }
}

impl ToSql for AddonPinnedDuration {
    fn to_sql(&self) -> rusqlite::Result<rusqlite::types::ToSqlOutput<'_>> {
        match self {
            AddonPinnedDuration::Days30 => "days_30".to_sql(),
            AddonPinnedDuration::Days7 => "days_7".to_sql(),
            AddonPinnedDuration::Hours24 => "days_1".to_sql(),
            AddonPinnedDuration::None => Ok(ToSqlOutput::from(Null)),
        }
    }
}

impl Job {
    pub fn to_slug() {}
}
