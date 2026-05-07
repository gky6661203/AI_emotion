use axum::{
    extract::{State, Path},
    Json,
};
use sqlx::PgPool;
use uuid::Uuid;

use crate::error::AppError;
use crate::models::{CreateLetterRequest, CreateLetterResponse, PrivateLetter};
use crate::AppState;
use super::devices::AuthUser;

pub async fn create_letter(
    State((pool, config): State<(sqlx::PgPool, AppState)>),
    Extension(auth_user): Extension<AuthUser>,
    Json(payload): Json<CreateLetterRequest>,
) -> Result<Json<CreateLetterResponse>, AppError> {
    let user_id = auth_user.0;
    let content_type = payload.content_type.unwrap_or_else(|| "text".into());
    let allow_ai_analysis = payload.allow_ai_analysis.unwrap_or(true);
    let write_to_emotion_profile = payload.write_to_emotion_profile.unwrap_or(true);

    let letter: PrivateLetter = sqlx::query_as(
        r#"
        INSERT INTO private_letters (user_id, title, content, content_type, allow_ai_analysis, write_to_emotion_profile, open_at, is_public)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING id, user_id, title, content, content_type, allow_ai_analysis, ai_summary,
                  keywords, emotion, emotion_intensity, write_to_emotion_profile,
                  affect_recommendation, affect_matching, open_at, is_public, created_at, deleted_at
        "#
    )
    .bind(user_id)
    .bind(&payload.title)
    .bind(&payload.content)
    .bind(&content_type)
    .bind(allow_ai_analysis)
    .bind(write_to_emotion_profile)
    .bind(&payload.open_at)
    .bind(payload.is_public.unwrap_or(false))
    .fetch_one(&pool)
    .await?;

    if allow_ai_analysis {
        if let Err(e) = analyze_letter_with_ai(&config.ai_engine_url, &letter.id, &payload.content).await {
            tracing::warn!("AI analysis failed for letter {}: {}", letter.id, e);
        }
    }

    Ok(Json(CreateLetterResponse { letter }))
}

pub async fn get_letter(
    State((pool, _): State<(sqlx::PgPool, AppState)>),
    Extension(auth_user): Extension<AuthUser>,
    Path(letter_id): Path<Uuid>,
) -> Result<Json<PrivateLetter>, AppError> {
    let user_id = auth_user.0;

    let letter: PrivateLetter = sqlx::query_as(
        r#"
        SELECT id, user_id, title, content, content_type, allow_ai_analysis, ai_summary,
               keywords, emotion, emotion_intensity, write_to_emotion_profile,
               affect_recommendation, affect_matching, open_at, is_public, created_at, deleted_at
        FROM private_letters
        WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL
        "#
    )
    .bind(letter_id)
    .bind(user_id)
    .fetch_optional(&pool)
    .await?
    .ok_or_else(|| AppError::NotFound("Letter not found".into()))?;

    Ok(Json(letter))
}

async fn analyze_letter_with_ai(ai_url: &str, letter_id: &Uuid, content: &str) -> Result<(), AppError> {
    let client = reqwest::Client::new();

    let payload = serde_json::json!({
        "letter_id": letter_id.to_string(),
        "content": content
    });

    client
        .post(format!("{}/v1/analyze/letter", ai_url))
        .json(&payload)
        .timeout(std::time::Duration::from_secs(30))
        .send()
        .await?;

    Ok(())
}