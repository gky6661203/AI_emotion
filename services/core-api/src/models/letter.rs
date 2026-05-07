use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct PrivateLetter {
    pub id: Uuid,
    pub user_id: Uuid,
    pub title: Option<String>,
    pub content: String,
    pub content_type: String,
    pub allow_ai_analysis: bool,
    pub ai_summary: Option<String>,
    pub keywords: Option<Vec<String>>,
    pub emotion: Option<String>,
    pub emotion_intensity: Option<f64>,
    pub write_to_emotion_profile: bool,
    pub affect_recommendation: Option<serde_json::Value>,
    pub affect_matching: Option<serde_json::Value>,
    pub open_at: Option<DateTime<Utc>>,
    pub is_public: bool,
    pub created_at: DateTime<Utc>,
    pub deleted_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateLetterRequest {
    pub title: Option<String>,
    pub content: String,
    pub content_type: Option<String>,
    pub allow_ai_analysis: Option<bool>,
    pub write_to_emotion_profile: Option<bool>,
    pub open_at: Option<DateTime<Utc>>,
    pub is_public: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateLetterResponse {
    pub letter: PrivateLetter,
}