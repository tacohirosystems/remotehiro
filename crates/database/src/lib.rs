use std::{collections::HashSet, path::PathBuf};

use rusqlite::{functions::FunctionFlags, Connection};
use serde_json::json;

pub fn json_concat_array(conn: &Connection) -> Result<(), rusqlite::Error> {
    conn.create_scalar_function(
        "json_concat_array",
        2,
        FunctionFlags::SQLITE_UTF8 | FunctionFlags::SQLITE_DETERMINISTIC,
        |ctx| -> Result<rusqlite::types::Value, rusqlite::Error> {
            let json_a = ctx.get::<serde_json::Value>(0)?;
            let json_b = ctx.get::<serde_json::Value>(1)?;

            let mut array_a = match json_a {
                serde_json::Value::Array(values) => Ok(values),
                _ => Err(rusqlite::Error::InvalidQuery),
            }?;

            let mut array_b = match json_b {
                serde_json::Value::Array(values) => Ok(values),
                _ => Err(rusqlite::Error::InvalidQuery),
            }?;

            array_a.append(&mut array_b);
            let mut seen = HashSet::new();
            array_a.retain(|v| seen.insert(v.to_string()));
            let array = json!(array_a);

            Ok(rusqlite::types::Value::Text(array.to_string()))
        },
    )
}

pub fn attach_warehouse_db(conn: &Connection, db_path: &PathBuf) -> Result<usize, rusqlite::Error> {
    conn.execute(
        "ATTACH DATABASE $1 AS warehouse;",
        rusqlite::params![db_path.to_str()],
    )
}

pub fn json_array_intersect(conn: &Connection) -> Result<(), rusqlite::Error> {
    conn.create_scalar_function(
        "json_array_intersect",
        2,
        FunctionFlags::SQLITE_UTF8 | FunctionFlags::SQLITE_DETERMINISTIC,
        |ctx| -> Result<bool, rusqlite::Error> {
            let json_a = ctx.get::<serde_json::Value>(0)?;
            let json_b = ctx.get::<serde_json::Value>(1)?;

            let mut array_a = match json_a {
                serde_json::Value::Array(values) => Ok(values),
                _ => Err(rusqlite::Error::InvalidQuery),
            }?;

            let mut array_b = match json_b {
                serde_json::Value::Array(values) => Ok(values),
                _ => Err(rusqlite::Error::InvalidQuery),
            }?;

            let has_intersection = array_a.iter().any(|a| array_b.contains(a));

            Ok(has_intersection)
        },
    )
}

pub fn detach_warehouse_db(conn: &mut Connection) -> Result<usize, rusqlite::Error> {
    conn.execute("DETACH DATABASE warehouse;", rusqlite::params![])
}

pub fn attach_remotehiro_db(
    conn: &Connection,
    db_path: &PathBuf,
) -> Result<usize, rusqlite::Error> {
    conn.execute(
        "ATTACH DATABASE $1 AS remotehiro;",
        rusqlite::params![db_path.to_str()],
    )
}

pub fn detach_remotehiro_db(conn: &mut Connection) -> Result<usize, rusqlite::Error> {
    conn.execute("DETACH DATABASE remotehiro;", rusqlite::params![])
}

pub fn attach_currency_exchange_db(
    conn: &Connection,
    db_path: &PathBuf,
) -> Result<usize, rusqlite::Error> {
    conn.execute(
        "ATTACH DATABASE $1 AS currency_exchange;",
        rusqlite::params![db_path.to_str()],
    )
}

pub fn detach_currency_exchange_db(conn: &mut Connection) -> Result<usize, rusqlite::Error> {
    conn.execute("DETACH DATABASE currency_exchange;", rusqlite::params![])
}
