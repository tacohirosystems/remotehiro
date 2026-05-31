use std::fmt::Display;

#[derive(Debug)]
pub enum DbError {
    Rusqlite(rusqlite::Error),
    Deserialize(serde_json::Error),
}

impl From<serde_json::Error> for DbError {
    fn from(err: serde_json::Error) -> Self {
        Self::Deserialize(err)
    }
}

impl From<rusqlite::Error> for DbError {
    fn from(err: rusqlite::Error) -> Self {
        Self::Rusqlite(err)
    }
}

impl From<rusqlite::types::FromSqlError> for DbError {
    fn from(err: rusqlite::types::FromSqlError) -> Self {
        Self::Rusqlite(rusqlite::Error::FromSqlConversionFailure(
            0,
            rusqlite::types::Type::Blob,
            Box::new(err),
        ))
    }
}

impl Display for DbError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            DbError::Rusqlite(error) => write!(f, "failed to execute query"),
            DbError::Deserialize(error) => write!(f, "failed to deserialize rows"),
        }
    }
}
