use axum::{
    extract::{State, Extension},
    Json,
};
use sqlx::PgPool;
use uuid::Uuid;

use crate::error::AppError;
use crate::models::{SendMessageRequest, SendMessageResponse, ChatMessage};
use crate::AppState;

#[derive(Clone)]
pub struct AuthUser(pub Uuid);

pub async fn send_message(
    State((pool, config): State<(sqlx::PgPool, AppState)>),
    Extension(auth_user): Extension<AuthUser>,
    Json(payload): Json<SendMessageRequest>,
) -> Result<Json<SendMessageResponse>, AppError> {
    let user_id = auth_user.0;
    let content_type = payload.content_type.unwrap_or_else(|| "text".into());

    let message: ChatMessage = sqlx::query_as(
        r#"
        INSERT INTO chat_messages (user_id, session_id, role, content, content_type)
        VALUES ($1, $2, 'user', $3, $4)
        RETURNING id, user_id, session_id, role, content, content_type, message_metadata, created_at
        "#
    )
    .bind(user_id)
    .bind(payload.session_id)
    .bind(&payload.content)
    .bind(&content_type)
    .fetch_one(&pool)
    .await?;

    sqlx::query("UPDATE users SET total_interactions = total_interactions + 1 WHERE id = $1")
        .bind(user_id)
        .execute(&pool)
        .await?;

    let ai_response = call_ai_engine(&config.ai_engine_url, &payload.content, &message.id).await?;

    Ok(Json(SendMessageResponse {
        message,
        ai_response,
    }))
}

async fn call_ai_engine(
    ai_url: &str,
    content: &str,
    message_id: &Uuid,
) -> Result<Option<ChatMessage>, AppError> {
    let client = reqwest::Client::new();

    let payload = serde_json::json!({
        "message": content,
        "message_id": message_id.to_string()
    });

    match client
        .post(format!("{}/v1/chat/completion", ai_url))
        .json(&payload)
        .timeout(std::time::Duration::from_secs(30))
        .send()
        .await
    {
        Ok(resp) if resp.status().is_success() => {
            let data: serde_json::Value = resp.json().await?;
            let ai_content = data.get("content").and_then(|c| c.as_str()).unwrap_or("");

            Ok(Some(ChatMessage {
                id: Uuid::new_v4(),
                user_id: Uuid::nil(),
                session_id: None,
                role: "assistant".into(),
                content: ai_content.to_string(),
                content_type: "text".into(),
                message_metadata: None,
                created_at: chrono::Utc::now(),
            }))
        }
        _ => Ok(None),
    }
}