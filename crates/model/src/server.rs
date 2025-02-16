use std::path::PathBuf;

use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct BuildInfo {
    pub nix_path: Option<PathBuf>,
    pub commit_hash: Option<String>,
    pub version: String,
}
