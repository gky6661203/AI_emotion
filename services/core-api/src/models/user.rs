use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct User {
    pub id: Uuid,
    pub anonymous_token: String,
    pub nickname: Option<String>,
    pub avatar_url: Option<String>,
    pub campus: Option<String>,
    pub enrollment_year: Option<i32>,
    pub risk_level: String,
    pub state_vector_id: Option<Uuid>,
    pub total_interactions: i32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub deleted_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateAnonymousRequest {
    pub campus: Option<String>,
    pub enrollment_year: Option<i32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateAnonymousResponse {
    pub user: User,
    pub token: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct UserStateVector {
    pub id: Uuid,
    pub user_id: Uuid,
    pub dimension_valence: f64,
    pub dimension_arousal: f64,
    pub dimension_dominance: f64,
    pub dimension_social: f64,
    pub dimension_cognitive: f64,
    pub vector_snapshot: Option<serde_json::Value>,
    pub computed_at: DateTime<Utc>,
}