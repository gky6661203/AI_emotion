use std::sync::Arc;
use axum::{
    Router,
    routing::{get, post},
    extract::{State, Path, Query, DefaultBodyLimit},
    middleware,
    body::Body,
    response::Json,
};
use sqlx::postgres::PgPoolOptions;
use tower_http::cors::{CorsLayer, Any};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

mod error;
mod config;
mod models;
mod handlers;
mod services;

use config::Config;
use error::AppError;

pub type AppState = Arc<Config>;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    dotenvy::dotenv().ok();

    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::new(
            std::env::var("RUST_LOG").unwrap_or_else(|_| "info".into())
        ))
        .with(tracing_subscriber::fmt::layer())
        .init();

    let config = Arc::new(Config::from_env()?);

    let pool = PgPoolOptions::new()
        .max_connections(10)
        .connect(&config.database_url)
        .await?;

    tracing::info!("Connected to database");

    let app = create_app(pool, config)
        .await?;

    let listener = tokio::net::TcpListener::bind(&config.server_addr)
        .await?;
    tracing::info!("Server listening on {}", config.server_addr);

    axum::serve(listener, app).await?;

    Ok(())
}

async fn create_app(
    pool: sqlx::PgPool,
    config: AppState,
) -> Result<Router, AppError> {
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    let app = Router::new()
        .route("/health", get(health_check))
        .route("/api/auth/anonymous", post(handlers::auth::create_anonymous))
        .route("/api/devices/bind", post(handlers::devices::bind_device))
        .route("/api/devices", get(handlers::devices::list_devices))
        .route("/api/chat/messages", post(handlers::chat::send_message))
        .route("/api/private-letters", post(handlers::letters::create_letter))
        .route("/api/private-letters/:id", get(handlers::letters::get_letter))
        .route("/api/voice-records", post(handlers::voice::upload_voice_record))
        .route("/api/voice-records/:id/transcribe", post(handlers::voice::transcribe))
        .route("/api/voice-records/:id/analyze", post(handlers::voice::analyze))
        .route("/api/voice-records/:id", get(handlers::voice::get_voice_record))
        .route("/api/recommendations/current", get(handlers::recommendations::get_current))
        .route("/api/emotions/report", get(handlers::emotions::get_report))
        .route("/ws/devices/sync", axum::routing::ws(handlers::ws_sync::device_sync))
        .layer(cors)
        .layer(DefaultBodyLimit::disable())
        .with_state((pool, config));

    Ok(app)
}

async fn health_check() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "status": "ok",
        "service": "core-api"
    }))
}