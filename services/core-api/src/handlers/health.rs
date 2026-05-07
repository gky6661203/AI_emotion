use axum::Json;
use sqlx::PgPool;
use crate::error::AppError;

pub async fn health_check(
    State((pool, _): State<(sqlx::PgPool, crate::AppState)>)
) -> Result<Json<serde_json::Value>, AppError> {
    sqlx::query("SELECT 1").execute(&pool).await?;

    Ok(Json(serde_json::json!({
        "status": "ok",
        "service": "core-api",
        "database": "connected"
    })))
}