use tracing_subscriber::filter::LevelFilter;

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_max_level(LevelFilter::INFO)
        // .with_env_filter(
        //     EnvFilter::try_from_default_env()
        //     .or_else(|_| EnvFilter::try_new("remotehiro=error,tower_http=info"))
        //     .unwrap()
        // )
        // .json()
        .init();

    if let Err(err) = server::run().await {
        eprintln!("failed to run server. reason: {:#?}", err)
    }
}
