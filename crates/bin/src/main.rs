use tracing_subscriber::filter::LevelFilter;

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_max_level(LevelFilter::INFO)
        .init();

    if let Err(err) = server::run().await {
        eprintln!("failed to run server. reason: {:#?}", err)
    }
}
