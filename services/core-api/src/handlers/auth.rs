use axum::{extract::State, Json};
use rand::Rng;
use sqlx::PgPool;
use uuid::Uuid;

use crate::error::AppError;
use crate::models::{CreateAnonymousRequest, CreateAnonymousResponse, User};
use crate::AppState;

pub async fn create_anonymous(
    State((pool, _): State<(sqlx::PgPool, AppState)>),
    Json(payload): Json<CreateAnonymousRequest>,
) -> Result<Json<CreateAnonymousResponse>, AppError> {
    let token: String = rand::thread_rng()
        .sample_iter(&rand::alphanumeric)
        .take(64)
        .map(char::from)
        .collect();

    let user: User = sqlx::query_as(
        r#"
        INSERT INTO users (anonymous_token, campus, enrollment_year, risk_level)
        VALUES ($1, $2, $3, 'low')
        RETURNING id, anonymous_token, nickname, avatar_url, campus, enrollment_year,
                  risk_level, state_vector_id, total_interactions, created_at, updated_at, deleted_at
        "#
    )
    .bind(&token)
    .bind(&payload.campus)
    .bind(&payload.enrollment_year)
    .fetch_one(&pool)
    .await?;

    let state_vector: Uuid = sqlx::query_scalar(
        r#"
        INSERT INTO user_state_vectors (user_id)
        VALUES ($1)
        RETURNING id
        "#
    )
    .bind(user.id)
    .fetch_one(&pool)
    .await?;

    sqlx::query("UPDATE users SET state_vector_id = $1 WHERE id = $2")
        .bind(state_vector)
        .bind(user.id)
        .execute(&pool)
        .await?;

    Ok(Json(CreateAnonymousResponse { user, token }))
}