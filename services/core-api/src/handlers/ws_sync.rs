use axum::{
    extract::{State, WebSocketUpgrade},
    ws::{Message, WebSocket},
    Json, Extension,
};
use std::sync::Arc;
use tokio::sync::broadcast;
use uuid::Uuid;

use crate::AppState;
use super::devices::AuthUser;

pub async fn device_sync(
    ws: WebSocketUpgrade,
    State((pool, config): State<(sqlx::PgPool, AppState)>),
    Extension(auth_user): Extension<AuthUser>,
) -> axum::response::Response {
    ws.on_upgrade(move |socket| handle_socket(socket, config, auth_user.0))
}

async fn handle_socket(
    socket: WebSocket,
    config: Arc<crate::config::Config>,
    user_id: Uuid,
) {
    let (sender, mut receiver) = broadcast::channel::<String>(100);

    let user_id_clone = user_id;

    sqlx::query("UPDATE devices SET last_sync_at = NOW() WHERE user_id = $1 AND is_active = true")
        .bind(user_id_clone)
        .execute(&*sqlx::PgPool::clone(&sqlx::PgPool::clone(&config.database_url.as_str())))
        .await
        .ok();

    let (ws_sender, mut ws_receiver) = socket.split();

    let send_task = tokio::spawn(async move {
        let mut sender = sender.subscribe();
        while let Ok(msg) = sender.recv().await {
            if ws_sender.send(Message::Text(msg.into())).await.is_err() {
                break;
            }
        }
    });

    let recv_task = tokio::spawn(async move {
        while let Some(Ok(Message::Text(text))) = ws_receiver.next().await {
            if let Err(e) = handle_sync_message(&text, user_id_clone).await {
                tracing::warn!("Sync message error: {}", e);
            }
        }
    });

    tokio::select! {
        _ = send_task => {}
        _ = recv_task => {}
    }
}

async fn handle_sync_message(msg: &str, user_id: Uuid) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let data: serde_json::Value = serde_json::from_str(msg)?;
    let action = data.get("action").and_then(|a| a.as_str()).unwrap_or("");

    match action {
        "ping" => {
            tracing::debug!("Device ping from user {:?}", user_id);
        }
        "sync_state" => {
            tracing::debug!("State sync from user {:?}", user_id);
        }
        _ => {}
    }

    Ok(())
}