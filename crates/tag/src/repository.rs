use rusqlite::Transaction;
use serde_json::json;

pub fn list<'t>(txn: &Transaction<'t>) -> Result<Vec<model::tag::Tag>, rusqlite::Error> {
    let mut statement = txn.prepare(crate::sql::SELECT_TAGS_QUERY)?;

    let tags = statement
        .query_map([], |row| model::tag::Tag::try_from(row))?
        .collect::<Result<Vec<model::tag::Tag>, _>>()?;

    Ok(tags)
}

pub fn bulk_upsert<'t>(
    txn: &Transaction<'t>,
    tags: Vec<&str>,
) -> Result<Vec<i64>, rusqlite::Error> {
    let mut statement = txn.prepare(crate::sql::INSERT_TAGS_QUERY)?;

    let tag_ids = statement
        .query_map(rusqlite::params![json!(tags)], |row| {
            row.get::<&str, i64>("id")
        })?
        .collect::<Result<Vec<i64>, _>>()?;

    Ok(tag_ids)
}
