use std::{
    collections::{HashMap, HashSet},
    net::SocketAddr,
    path::PathBuf,
    sync::Arc,
};

use axum::{extract::Request, http::StatusCode, response::IntoResponse, routing};
use minijinja::{context, Value};
use serde::Deserialize;
use time::Duration;
use tokio::signal;
use tower_http::services::ServeDir;

const DATABASE_PATH: &str = "REMOTEHIRO_DATABASE_PATH";
const WAREHOUSE_DATABASE_PATH: &str = "REMOTEHIRO_WAREHOUSE_DATABASE_PATH";
const CURRENCY_EXCHANGE_DATABASE_PATH: &str = "REMOTEHIRO_CURRENCY_EXCHANGE_DATABASE_PATH";
const TEMPLATES_PATH: &str = "REMOTEHIRO_SERVER_TEMPLATES_PATH";
const STATIC_ASSETS_PATH: &str = "REMOTEHIRO_SERVER_STATIC_ASSETS_PATH";
const COMMIT_HASH: &str = "REMOTEHIRO_SERVER_COMMIT_HASH";
const VERSION: &str = "REMOTEHIRO_SERVER_VERSION";
const NIX_PATH: &str = "REMOTEHIRO_SERVER_NIX_PATH";

#[derive(Clone, Debug)]
pub struct ServerConfig {
    pub static_assets_path: PathBuf,
    pub templates_path: PathBuf,
    pub build_info: model::server::BuildInfo,
}

#[derive(Debug)]
pub enum ServerConfigError<'k> {
    Var {
        key: &'k str,
        source: std::env::VarError,
    },
    PaddleEnvironment,
}

impl std::fmt::Display for ServerConfigError<'_> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ServerConfigError::Var {
                key,
                source: std::env::VarError::NotPresent,
            } => write!(f, "{key} is not present"),
            ServerConfigError::Var {
                key,
                source: std::env::VarError::NotUnicode(_),
            } => write!(f, "{key} must be a valid unicode"),
            ServerConfigError::PaddleEnvironment => write!(
                f,
                "invalid paddle environment value. must be sandbox, or production"
            ),
        }
    }
}

impl std::error::Error for ServerConfigError<'_> {}

impl ServerConfig {
    pub fn from_env<'k>() -> Result<Self, ServerConfigError<'k>> {
        let static_assets_path =
            PathBuf::from(std::env::var(STATIC_ASSETS_PATH).map_err(|error| {
                ServerConfigError::Var {
                    key: STATIC_ASSETS_PATH,
                    source: error,
                }
            })?);

        let templates_path = PathBuf::from(std::env::var(TEMPLATES_PATH).map_err(|error| {
            ServerConfigError::Var {
                key: TEMPLATES_PATH,
                source: error,
            }
        })?);

        let nix_path = std::env::var(NIX_PATH).ok().map(|path| PathBuf::from(path));
        let commit_hash = std::env::var(COMMIT_HASH).ok();
        let version = std::env::var(VERSION).ok().unwrap_or("dev".to_string());

        let config = Self {
            static_assets_path,
            templates_path,
            build_info: model::server::BuildInfo {
                nix_path,
                commit_hash,
                version,
            },
        };
        Ok(config)
    }
}

#[derive(Debug)]
pub enum ServerError<'k> {
    Io(std::io::Error),
    Config(ServerConfigError<'k>),
    SqliteHandle(su_sqlite::handle::CreateHandleError),
}

impl std::error::Error for ServerError<'_> {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        None
    }

    fn cause(&self) -> Option<&dyn std::error::Error> {
        self.source()
    }
}

impl From<std::io::Error> for ServerError<'_> {
    fn from(value: std::io::Error) -> Self {
        Self::Io(value)
    }
}

impl<'k> From<ServerConfigError<'k>> for ServerError<'k> {
    fn from(value: ServerConfigError<'k>) -> ServerError<'k> {
        Self::Config(value)
    }
}

impl<'k> From<su_sqlite::handle::CreateHandleError> for ServerError<'k> {
    fn from(err: su_sqlite::handle::CreateHandleError) -> Self {
        Self::SqliteHandle(err)
    }
}

impl std::fmt::Display for ServerError<'_> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ServerError::Io(error) => write!(f, "{}", error),
            ServerError::Config(config_error) => write!(f, "{}", config_error),
            ServerError::SqliteHandle(create_handle_error) => write!(f, "{}", create_handle_error),
        }
    }
}

#[derive(Debug)]
pub enum SitemapError {
    Repo(job::service::RepoError),
    Template(su_template::RenderTemplateError),
}

impl std::error::Error for SitemapError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        None
    }

    fn cause(&self) -> Option<&dyn std::error::Error> {
        self.source()
    }
}

impl From<job::service::RepoError> for SitemapError {
    fn from(value: job::service::RepoError) -> Self {
        Self::Repo(value)
    }
}

impl From<su_template::RenderTemplateError> for SitemapError {
    fn from(value: su_template::RenderTemplateError) -> Self {
        Self::Template(value)
    }
}

impl std::fmt::Display for SitemapError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            SitemapError::Repo(repo_error) => write!(f, "{}", repo_error),
            SitemapError::Template(render_template_error) => write!(f, "{}", render_template_error),
        }
    }
}

impl IntoResponse for SitemapError {
    fn into_response(self) -> axum::response::Response {
        tracing::error!("failed to get_index. reason: {:#?}", self);
        (StatusCode::INTERNAL_SERVER_ERROR, "Something went wrong").into_response()
    }
}

pub async fn run<'k>() -> Result<(), ServerError<'k>> {
    // Server configuration
    let server_config = ServerConfig::from_env()?;

    // Database handle
    let database_path =
        PathBuf::from(
            std::env::var(DATABASE_PATH).map_err(|err| ServerConfigError::Var {
                key: DATABASE_PATH,
                source: err,
            })?,
        );

    let mut db_handle = su_sqlite::handle::Handle::builder(database_path.clone());

    db_handle.set_post_create(Some(|conn| {
        database::json_concat_array(&conn)?;
        database::json_array_intersect(&conn)?;
        Ok(())
    }));

    let db_handle = db_handle.build()?;
    let db_handle = Arc::new(db_handle);

    // Warehouse database handle
    let warehouse_db_path =
        PathBuf::from(std::env::var(WAREHOUSE_DATABASE_PATH).map_err(|err| {
            ServerConfigError::Var {
                key: WAREHOUSE_DATABASE_PATH,
                source: err,
            }
        })?);

    let warehouse_db_handle =
        su_sqlite::handle::Handle::builder(warehouse_db_path.clone()).build()?;
    let warehouse_db_handle = Arc::new(warehouse_db_handle);

    // Currency exchange DB
    let currency_exchange_db_path = PathBuf::from(
        std::env::var(CURRENCY_EXCHANGE_DATABASE_PATH).map_err(|err| ServerConfigError::Var {
            key: CURRENCY_EXCHANGE_DATABASE_PATH,
            source: err,
        })?,
    );

    // Templating handle
    let mut template_builder = su_template::Handle::builder();
    let env = template_builder.get_mut_env();

    minijinja_contrib::add_to_environment(env);

    env.set_loader(minijinja::path_loader(
        server_config.templates_path.as_path(),
    ));

    env.add_filter("comma_split", comma_split);
    env.add_filter("human_duration", human_duration);
    env.add_filter("slugify", slug::slugify::<String>);
    env.add_filter("render_markdown", render_markdown);
    env.add_filter("a11y_fg_color", a11y_fg_color);
    env.add_function("bool", bool_fn);
    env.add_function("a11y_color", a11y_color);
    env.add_function("string_array_contains", string_array_contains);

    let template_handle = template_builder.build_static();
    let addr = SocketAddr::from(([0, 0, 0, 0], 3000));
    let listener = tokio::net::TcpListener::bind(addr).await?;
    let job_env = job::HandlerEnv::new(
        db_handle.clone(),
        template_handle.clone(),
        server_config.build_info.clone(),
        currency_exchange_db_path.clone(),
        warehouse_db_path.clone(),
    );

    let warehouse_env = warehouse::HandlerEnv::new(
        warehouse_db_handle.clone(),
        database_path.clone(),
        currency_exchange_db_path,
    );

    let app = axum::Router::new()
        .merge(job_env.routes())
        .merge(warehouse_env.routes())
        // TODO: Move somewhere when this can be grouped with other things maybe.
        .route(
            "/sitemap.xml",
            routing::get(async move || -> Result<String, SitemapError> {
                let jobs = job::service::list_jobs(
                    &db_handle,
                    model::job::IndexFilters {
                        query: None,
                        min_salary: None,
                        tags: None,
                        employment_types: None,
                        regions: None,
                        subregions: None,
                        countries: None,
                        categories: None,
                        currency: None,
                    },
                    warehouse_db_path,
                )
                .await?;

                let context = context!(jobs => jobs);

                let xml = template_handle
                    .clone()
                    .render_template(context, "sitemap.xml")?;

                Ok(xml)
            }),
        )
        .route(
            "/robots.txt",
            routing::get(|| async {
                "User-agent: *\nAllow: /\n\nSitemap: https://www.remotehiro.com/sitemap.xml\n"
            }),
        )
        .layer(
            tower_http::trace::TraceLayer::new_for_http().make_span_with(|request: &Request<_>| {
                tracing::info_span!(
                    "request",
                    method = %request.method(),
                    uri = %request.uri(),
                    headers = ?request.headers(),
                    version = ?request.version(),
                )
            }),
        )
        .layer(tower_http::compression::CompressionLayer::new())
        .nest_service(
            "/assets",
            ServeDir::new(server_config.static_assets_path.as_path())
                .precompressed_br()
                .precompressed_gzip(),
        );

    axum::serve(listener, app)
        .with_graceful_shutdown(shutdown_signal())
        .await?;

    Ok(())
}

fn bool_fn(predicate: bool, val_a: Value, val_b: Value) -> Value {
    if predicate {
        val_a
    } else {
        val_b
    }
}

async fn shutdown_signal() {
    let ctrl_c = async {
        signal::ctrl_c()
            .await
            .expect("failed to install Ctrl+C handler");
    };

    #[cfg(unix)]
    let terminate = async {
        signal::unix::signal(signal::unix::SignalKind::terminate())
            .expect("failed to install signal handler")
            .recv()
            .await;
    };

    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();

    tokio::select! {
        _ = ctrl_c => {},
        _ = terminate => {},
    }
}

fn comma_split(value: minijinja::Value) -> Result<String, minijinja::Error> {
    let figure = value.as_i64().ok_or(minijinja::Error::new(
        minijinja::ErrorKind::CannotDeserialize,
        "invalid number type",
    ))?;

    Ok(figure.to_string())
}

fn human_duration(value: minijinja::Value) -> Result<String, minijinja::Error> {
    let duration = Duration::deserialize(value)?;

    let str = match duration.whole_seconds() {
        dur if dur < 60 => format!("{}s", dur),
        dur if (60..3_600).contains(&dur) => format!("{}m", duration.whole_minutes()),
        dur if (3_600..86_400).contains(&dur) => format!("{}h", duration.whole_hours()),
        _dur => format!("{}d", duration.whole_days()),
    };

    Ok(str)
}

fn render_markdown(markdown_input: String) -> String {
    let parser = pulldown_cmark::Parser::new(markdown_input.as_str());
    let mut html_output = String::new();

    pulldown_cmark::html::push_html(&mut html_output, parser);

    let mut url_schemes = HashSet::new();
    url_schemes.insert("https");

    let html_output = ammonia::Builder::new()
        .url_schemes(url_schemes)
        .url_relative(ammonia::UrlRelative::Deny)
        .link_rel(Some("noopener noreferrer nofollow"))
        .strip_comments(true)
        .clean(html_output.as_str())
        .to_string();

    html_output
}

fn a11y_fg_color(color_hex: String) -> Option<i64> {
    let chars: Vec<char> = color_hex.chars().collect();
    let chunks: Vec<_> = chars
        .chunks(2)
        .map(|chunk| chunk.iter().collect::<String>())
        .collect();

    tracing::debug!("{:#?}", chunks);

    match chunks.as_slice() {
        [r, g, b] => {
            let r = i64::from_str_radix(r.as_str(), 16).ok()?;
            let g = i64::from_str_radix(g.as_str(), 16).ok()?;
            let b = i64::from_str_radix(b.as_str(), 16).ok()?;

            Some((((r * 299) + (g * 587) + (b * 114)) / 1000 - 128) * -1000)
        }
        _ => None,
    }
}

fn a11y_color(predicate: bool, bg_color_hex: String) -> String {
    if predicate {
        if let Some(num) = a11y_fg_color(bg_color_hex.clone()) {
            format!(
                "background: #{bg_color_hex};color:rgb({:?},{:?},{:?});",
                num, num, num
            )
        } else {
            "".to_owned()
        }
    } else {
        "".to_owned()
    }
}

fn string_array_contains(source: Vec<String>, dest: Vec<String>) -> bool {
    let mut dest_map = HashMap::with_capacity(dest.len());

    for dest_el in dest.into_iter() {
        dest_map.insert(dest_el, ());
    }

    for source_el in source.iter() {
        if let None = dest_map.get(source_el) {
            return false;
        }
    }
    return true;
}
