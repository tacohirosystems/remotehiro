use serde::{Deserialize, Serialize};

#[derive(Clone, Copy, Debug, Deserialize, Serialize)]
pub struct CategoryId(pub i64);

#[derive(Debug, Serialize)]
pub struct Category {
    pub id: i64,
    pub name: String,
}

impl TryFrom<&rusqlite::Row<'_>> for Category {
    type Error = rusqlite::Error;

    fn try_from(row: &rusqlite::Row<'_>) -> Result<Self, Self::Error> {
        Ok(Category {
            id: row.get("id")?,
            name: row.get("name")?,
        })
    }
}
