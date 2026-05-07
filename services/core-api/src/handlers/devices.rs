use axum::{
    extract::{State, Query},
    Json,
    headers::{Authorization, Bearer},
};
use sqlx::PgPool;
use uuid::Uuid;

use crate::error::AppError;
use crate::models::{BindDeviceRequest, BindDeviceResponse, Device};
use crate::AppState;

pub async fn bind_device(
    State((pool, _): State<(sqlx::PgPool, AppState)>),
    headers: Authorization<Bearer>,
    Json(payload): Json<BindDeviceRequest>,
) -> Result<Json<BindDeviceResponse>, AppError> {
    let token = headers.token();
    let user = get_user_by_token(&pool, token).await?;

    let device: Device = sqlx::query_as(
        r#"
        INSERT INTO devices (user_id, device_id, device_type, device_name, os_version, app_version)
        VALUES ($1, $2, $3, $4, $5, $6)
        ON CONFLICT (device_id) DO UPDATE SET
            user_id = EXCLUDED.user_id,
            device_name = EXCLUDED.device_name,
            os_version = EXCLUDED.os_version,
            app_version = EXCLUDED.app_version,
            last_sync_at = NOW(),
            is_active = true
        RETURNING id, user_id, device_id, device_type, device_name, os_version, app_version,
                  last_sync_at, is_active, created_at
        "#
    )
    .bind(user.id)
    .bind(&payload.device_id)
    .bind(&payload.device_type)
    .bind(&payload.device_name)
    .bind(&payload.os_version)
    .bind(&payload.app_version)
    .fetch_one(&pool)
    .await?;

    Ok(Json(BindDeviceResponse { device }))
}

pub async fn list_devices(
    State((pool, _): State<(sqlx::PgPool, AppState)>),
    headers: Authorization<Bearer>,
) -> Result<Json<Vec<Device>>, AppError> {
    let token = headers.token();
    let user = get_user_by_token(&pool, token).await?;

    let devices: Vec<Device> = sqlx::query_as(
        r#"
        SELECT id, user_id, device_id, device_type, device_name, os_version, app_version,
               last_sync_at, is_active, created_at
        FROM devices
        WHERE user_id = $1 AND is_active = true
        ORDER BY last_sync_at DESC NULLS LAST
        "#
    )
    .bind(user.id)
    .fetch_all(&pool)
    .await?;

    Ok(Json(devices))
}

pub async fn get_user_by_token(pool: &PgPool, token: &str) -> Result<User, AppError> {
    let user = sqlx::query_as(
        r#"
        SELECT id, anonymous_token, nickname, avatar_url, campus, enrollment_year,
               risk_level, state_vector_id, total_interactions, created_at, updated_at, deleted_at
        FROM users
        WHERE anonymous_token = $1 AND deleted_at IS NULL
        "#
    )
    .bind(token)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| AppError::Unauthorized)?;

    Ok(user)
}

use crate::models::User;