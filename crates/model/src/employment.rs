use serde::{Deserialize, Serialize};

#[derive(Clone, Copy, Debug, Deserialize, Serialize)]
pub struct EmploymentTypeId(pub i64);

#[derive(Debug, Serialize)]
pub struct EmploymentType {
    pub id: i64,
    pub name: String,
}

impl TryFrom<&rusqlite::Row<'_>> for EmploymentType {
    type Error = rusqlite::Error;

    fn try_from(row: &rusqlite::Row<'_>) -> Result<Self, Self::Error> {
        Ok(EmploymentType {
            id: row.get("id")?,
            name: row.get("name")?,
        })
    }
}
