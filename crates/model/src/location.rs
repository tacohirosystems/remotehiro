use rusqlite::types::FromSql;
use serde::{Deserialize, Serialize};

#[derive(Clone, Copy, Debug, Deserialize, Serialize)]
#[serde(transparent)]
pub struct RegionId(pub i64);

#[derive(Clone, Copy, Debug, Deserialize, Serialize)]
#[serde(transparent)]
pub struct SubregionId(pub i64);

#[derive(Clone, Copy, Debug, Deserialize, Serialize)]
#[serde(transparent)]
pub struct CountryId(pub i64);

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Country {
    pub id: CountryId,
    pub iso2: String,
    pub name: String,
}

#[derive(Debug, Serialize)]
pub struct Region {
    pub id: RegionId,
    pub name: String,
}

impl FromSql for CountryId {
    fn column_result(value: rusqlite::types::ValueRef<'_>) -> rusqlite::types::FromSqlResult<Self> {
        let country_id = value.as_i64()?;
        Ok(CountryId(country_id))
    }
}

impl FromSql for RegionId {
    fn column_result(value: rusqlite::types::ValueRef<'_>) -> rusqlite::types::FromSqlResult<Self> {
        let region_id = value.as_i64()?;
        Ok(RegionId(region_id))
    }
}

impl FromSql for SubregionId {
    fn column_result(value: rusqlite::types::ValueRef<'_>) -> rusqlite::types::FromSqlResult<Self> {
        let subregion_id = value.as_i64()?;
        Ok(SubregionId(subregion_id))
    }
}

impl TryFrom<&rusqlite::Row<'_>> for Region {
    type Error = rusqlite::Error;

    fn try_from(row: &rusqlite::Row<'_>) -> Result<Self, Self::Error> {
        Ok(Region {
            id: row.get("region_id")?,
            name: row.get("name")?,
        })
    }
}

impl TryFrom<&rusqlite::Row<'_>> for Country {
    type Error = rusqlite::Error;

    fn try_from(row: &rusqlite::Row<'_>) -> Result<Self, Self::Error> {
        Ok(Country {
            id: row.get("country_id")?,
            name: row.get("name")?,
            iso2: row.get("iso2")?,
        })
    }
}
