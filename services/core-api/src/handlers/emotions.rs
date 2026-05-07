use axum::{
    extract::{State, Query},
    Json,
};
use chrono::{Duration, Utc};
use sqlx::PgPool;

use crate::error::AppError;
use crate::models::{EmotionReport, EmotionRecord, EmotionCount};
use crate::AppState;
use super::devices::AuthUser;

#[derive(Debug, Deserialize)]
pub struct ReportQuery {
    pub days: Option<i32>,
}

pub async fn get_report(
    State((pool, _): State<(sqlx::PgPool, AppState)>),
    Extension(auth_user): Extension<AuthUser>,
    Query(query): Query<ReportQuery>,
) -> Result<Json<EmotionReport>, AppError> {
    let user_id = auth_user.0;
    let days = query.days.unwrap_or(7) as i64;
    let period_end = Utc::now();
    let period_start = period_end - Duration::days(days);

    let total_records: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM emotion_records WHERE user_id = $1 AND created_at >= $2"
    )
    .bind(user_id)
    .bind(period_start)
    .fetch_one(&pool)
    .await?;

    let risk_events_count: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM risk_events WHERE user_id = $1 AND created_at >= $2 AND handled = false"
    )
    .bind(user_id)
    .bind(period_start)
    .fetch_one(&pool)
    .await?;

    let emotion_distribution: Vec<EmotionCount> = sqlx::query_as(
        r#"
        SELECT emotion, COUNT(*) as count
        FROM emotion_records
        WHERE user_id = $1 AND created_at >= $2
        GROUP BY emotion
        ORDER BY count DESC
        "#
    )
    .bind(user_id)
    .bind(period_start)
    .fetch_all(&pool)
    .await?;

    let dominant_emotion = emotion_distribution.first()
        .map(|e| e.emotion.clone())
        .unwrap_or_else(|| "neutral".to_string());

    let avg_intensity: f64 = sqlx::query_scalar(
        "SELECT COALESCE(AVG(intensity), 0.5) FROM emotion_records WHERE user_id = $1 AND created_at >= $2"
    )
    .bind(user_id)
    .bind(period_start)
    .fetch_one(&pool)
    .await?;

    let recent_records: Vec<EmotionRecord> = sqlx::query_as(
        r#"
        SELECT id, user_id, emotion, intensity, source, source_id, keywords,
               ai_summary, trigger_type, risk_detected, created_at
        FROM emotion_records
        WHERE user_id = $1 AND created_at >= $2
        ORDER BY created_at DESC
        LIMIT 20
        "#
    )
    .bind(user_id)
    .bind(period_start)
    .fetch_all(&pool)
    .await?;

    Ok(Json(EmotionReport {
        user_id,
        period_start,
        period_end,
        dominant_emotion,
        average_intensity: avg_intensity,
        total_records,
        risk_events_count,
        emotion_distribution,
        recent_records,
    }))
}