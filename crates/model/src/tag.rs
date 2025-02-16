use serde::{Deserialize, Serialize};

#[derive(Clone, Copy, Debug, Deserialize, Serialize)]
pub struct TagId(pub i64);

#[derive(Debug, Serialize)]
pub struct Tag {
    pub id: i64,
    pub name: String,
    pub count: i64,
}

impl TryFrom<&rusqlite::Row<'_>> for Tag {
    type Error = rusqlite::Error;

    fn try_from(row: &rusqlite::Row<'_>) -> Result<Self, Self::Error> {
        Ok(Tag {
            id: row.get("id")?,
            name: row.get("name")?,
            count: row.get("count")?,
        })
    }
}
