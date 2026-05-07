use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct VoiceRecord {
    pub id: Uuid,
    pub user_id: Uuid,
    pub file_url: String,
    pub file_key: Option<String>,
    pub duration_seconds: Option<i32>,
    pub transcript: Option<String>,
    pub emotion: Option<String>,
    pub emotion_intensity: Option<f64>,
    pub voice_features: Option<serde_json::Value>,
    pub ai_summary: Option<String>,
    pub keywords: Option<Vec<String>>,
    pub risk_level: String,
    pub transcription_status: String,
    pub analysis_status: String,
    pub allow_ai_analysis: bool,
    pub write_to_emotion_profile: bool,
    pub created_at: DateTime<Utc>,
    pub deleted_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UploadVoiceRequest {
    pub file_url: String,
    pub file_key: Option<String>,
    pub duration_seconds: Option<i32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UploadVoiceResponse {
    pub voice_record: VoiceRecord,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TranscribeResponse {
    pub voice_record: VoiceRecord,
    pub transcript: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AnalyzeResponse {
    pub voice_record: VoiceRecord,
    pub emotion: String,
    pub emotion_intensity: f64,
    pub keywords: Vec<String>,
    pub ai_summary: String,
    pub risk_level: String,
}