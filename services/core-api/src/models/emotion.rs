use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct EmotionRecord {
    pub id: Uuid,
    pub user_id: Uuid,
    pub emotion: String,
    pub intensity: f64,
    pub source: Option<String>,
    pub source_id: Option<Uuid>,
    pub keywords: Option<Vec<String>>,
    pub ai_summary: Option<String>,
    pub trigger_type: Option<String>,
    pub risk_detected: bool,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EmotionReport {
    pub user_id: Uuid,
    pub period_start: DateTime<Utc>,
    pub period_end: DateTime<Utc>,
    pub dominant_emotion: String,
    pub average_intensity: f64,
    pub total_records: i64,
    pub risk_events_count: i64,
    pub emotion_distribution: Vec<EmotionCount>,
    pub recent_records: Vec<EmotionRecord>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EmotionCount {
    pub emotion: String,
    pub count: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Recommendation {
    pub recommendation_type: String,
    pub title: String,
    pub description: Option<String>,
    pub priority: i32,
    pub data: Option<serde_json::Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CurrentRecommendations {
    pub user_id: Uuid,
    pub recommendations: Vec<Recommendation>,
    pub generated_at: DateTime<Utc>,
}