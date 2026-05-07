use axum::{
    extract::{State, Query},
    Json,
};
use chrono::{Duration, Utc};
use sqlx::PgPool;
use uuid::Uuid;

use crate::error::AppError;
use crate::models::{CurrentRecommendations, Recommendation};
use crate::AppState;
use super::devices::AuthUser;

#[derive(Debug, Deserialize)]
pub struct RecommendationsQuery {
    pub limit: Option<i32>,
}

pub async fn get_current(
    State((pool, config): State<(sqlx::PgPool, AppState)>),
    Extension(auth_user): Extension<AuthUser>,
    Query(query): Query<RecommendationsQuery>,
) -> Result<Json<CurrentRecommendations>, AppError> {
    let user_id = auth_user.0;
    let limit = query.limit.unwrap_or(5);

    let user_state = get_user_emotion_state(&pool, user_id).await?;

    let recommendations = generate_recommendations(&config.ai_engine_url, &user_state, limit).await?;

    Ok(Json(CurrentRecommendations {
        user_id,
        recommendations,
        generated_at: Utc::now(),
    }))
}

async fn get_user_emotion_state(
    pool: &PgPool,
    user_id: Uuid,
) -> Result<UserEmotionState, AppError> {
    let state = sqlx::query_as(
        r#"
        SELECT dimension_valence, dimension_arousal, dimension_dominance,
               dimension_social, dimension_cognitive
        FROM user_state_vectors
        WHERE user_id = $1
        ORDER BY computed_at DESC
        LIMIT 1
        "#
    )
    .bind(user_id)
    .fetch_optional(pool)
    .await?;

    let recent_emotions = sqlx::query_as(
        r#"
        SELECT emotion, intensity
        FROM emotion_records
        WHERE user_id = $1 AND created_at > $2
        ORDER BY created_at DESC
        LIMIT 10
        "#
    )
    .bind(user_id)
    .bind(Utc::now() - Duration::days(7))
    .fetch_all(pool)
    .await
    .unwrap_or_default();

    Ok(UserEmotionState {
        valence: state.as_ref().map(|s: &UserStateVec| s.dimension_valence).unwrap_or(0.5),
        arousal: state.as_ref().map(|s| s.dimension_arousal).unwrap_or(0.5),
        dominance: state.as_ref().map(|s| s.dimension_dominance).unwrap_or(0.5),
        social: state.as_ref().map(|s| s.dimension_social).unwrap_or(0.5),
        cognitive: state.as_ref().map(|s| s.dimension_cognitive).unwrap_or(0.5),
        recent_emotions,
    })
}

async fn generate_recommendations(
    ai_url: &str,
    state: &UserEmotionState,
    limit: i32,
) -> Result<Vec<Recommendation>, AppError> {
    let client = reqwest::Client::new();

    let payload = serde_json::json!({
        "emotion_state": state,
        "limit": limit
    });

    match client
        .post(format!("{}/v1/recommend/current", ai_url))
        .json(&payload)
        .timeout(std::time::Duration::from_secs(10))
        .send()
        .await
    {
        Ok(resp) if resp.status().is_success() => {
            let data: serde_json::Value = resp.json().await?;
            let recs = data.get("recommendations")
                .and_then(|r| r.as_array())
                .map(|arr| {
                    arr.iter().filter_map(|item| {
                        Some(Recommendation {
                            recommendation_type: item.get("type")?.as_str()?.to_string(),
                            title: item.get("title")?.as_str()?.to_string(),
                            description: item.get("description").and_then(|d| d.as_str()).map(String::from),
                            priority: item.get("priority")?.as_i64().unwrap_or(0) as i32,
                            data: item.get("data").cloned(),
                        })
                    }).collect()
                })
                .unwrap_or_else(default_recommendations);

            Ok(recs)
        }
        _ => Ok(default_recommendations()),
    }
}

fn default_recommendations() -> Vec<Recommendation> {
    vec![
        Recommendation {
            recommendation_type: "companion".to_string(),
            title: "AI 陪伴聊天".to_string(),
            description: Some("随时在这里倾听你".to_string()),
            priority: 1,
            data: None,
        },
        Recommendation {
            recommendation_type: "treehole".to_string(),
            title: "写下心事".to_string(),
            description: Some("私密树洞，AI 帮你整理情绪".to_string()),
            priority: 2,
            data: None,
        },
        Recommendation {
            recommendation_type: "voice".to_string(),
            title: "语音记录".to_string(),
            description: Some("说出你的感受".to_string()),
            priority: 3,
            data: None,
        },
    ]
}

#[derive(Debug)]
struct UserEmotionState {
    valence: f64,
    arousal: f64,
    dominance: f64,
    social: f64,
    cognitive: f64,
    recent_emotions: Vec<RecentEmotion>,
}

#[derive(Debug)]
struct RecentEmotion {
    emotion: String,
    intensity: f64,
}

#[derive(Debug)]
struct UserStateVec {
    dimension_valence: f64,
    dimension_arousal: f64,
    dimension_dominance: f64,
    dimension_social: f64,
    dimension_cognitive: f64,
}