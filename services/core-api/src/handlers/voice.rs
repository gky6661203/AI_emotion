use axum::{
    extract::{State, Path},
    Json,
};
use sqlx::PgPool;
use uuid::Uuid;

use crate::error::AppError;
use crate::models::{VoiceRecord, UploadVoiceRequest, UploadVoiceResponse, TranscribeResponse, AnalyzeResponse};
use crate::AppState;
use super::devices::AuthUser;

pub async fn upload_voice_record(
    State((pool, _): State<(sqlx::PgPool, AppState)>),
    Extension(auth_user): Extension<AuthUser>,
    Json(payload): Json<UploadVoiceRequest>,
) -> Result<Json<UploadVoiceResponse>, AppError> {
    let user_id = auth_user.0;

    let voice_record: VoiceRecord = sqlx::query_as(
        r#"
        INSERT INTO voice_records (user_id, file_url, file_key, duration_seconds, risk_level, transcription_status, analysis_status)
        VALUES ($1, $2, $3, $4, 'low', 'pending', 'pending')
        RETURNING id, user_id, file_url, file_key, duration_seconds, transcript, emotion,
                  emotion_intensity, voice_features, ai_summary, keywords, risk_level,
                  transcription_status, analysis_status, allow_ai_analysis, write_to_emotion_profile,
                  created_at, deleted_at
        "#
    )
    .bind(user_id)
    .bind(&payload.file_url)
    .bind(&payload.file_key)
    .bind(&payload.duration_seconds)
    .fetch_one(&pool)
    .await?;

    Ok(Json(UploadVoiceResponse { voice_record }))
}

pub async fn get_voice_record(
    State((pool, _): State<(sqlx::PgPool, AppState)>),
    Extension(auth_user): Extension<AuthUser>,
    Path(record_id): Path<Uuid>,
) -> Result<Json<VoiceRecord>, AppError> {
    let user_id = auth_user.0;

    let voice_record: VoiceRecord = sqlx::query_as(
        r#"
        SELECT id, user_id, file_url, file_key, duration_seconds, transcript, emotion,
               emotion_intensity, voice_features, ai_summary, keywords, risk_level,
               transcription_status, analysis_status, allow_ai_analysis, write_to_emotion_profile,
               created_at, deleted_at
        FROM voice_records
        WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL
        "#
    )
    .bind(record_id)
    .bind(user_id)
    .fetch_optional(&pool)
    .await?
    .ok_or_else(|| AppError::NotFound("Voice record not found".into()))?;

    Ok(Json(voice_record))
}

pub async fn transcribe(
    State((pool, config): State<(sqlx::PgPool, AppState)>),
    Extension(auth_user): Extension<AuthUser>,
    Path(record_id): Path<Uuid>,
) -> Result<Json<TranscribeResponse>, AppError> {
    let user_id = auth_user.0;

    let voice_record: VoiceRecord = sqlx::query_as(
        r#"
        SELECT id, user_id, file_url, file_key, duration_seconds, transcript, emotion,
               emotion_intensity, voice_features, ai_summary, keywords, risk_level,
               transcription_status, analysis_status, allow_ai_analysis, write_to_emotion_profile,
               created_at, deleted_at
        FROM voice_records
        WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL
        "#
    )
    .bind(record_id)
    .bind(user_id)
    .fetch_optional(&pool)
    .await?
    .ok_or_else(|| AppError::NotFound("Voice record not found".into()))?;

    sqlx::query("UPDATE voice_records SET transcription_status = 'processing' WHERE id = $1")
        .bind(record_id)
        .execute(&pool)
        .await?;

    let transcript = call_asr(&config.ai_engine_url, &voice_record.file_url).await?;

    let updated: VoiceRecord = sqlx::query_as(
        r#"
        UPDATE voice_records
        SET transcript = $1, transcription_status = 'completed'
        WHERE id = $2
        RETURNING id, user_id, file_url, file_key, duration_seconds, transcript, emotion,
                   emotion_intensity, voice_features, ai_summary, keywords, risk_level,
                   transcription_status, analysis_status, allow_ai_analysis, write_to_emotion_profile,
                   created_at, deleted_at
        "#
    )
    .bind(&transcript)
    .bind(record_id)
    .fetch_one(&pool)
    .await?;

    Ok(Json(TranscribeResponse {
        voice_record: updated,
        transcript,
    }))
}

pub async fn analyze(
    State((pool, config): State<(sqlx::PgPool, AppState)>),
    Extension(auth_user): Extension<AuthUser>,
    Path(record_id): Path<Uuid>,
) -> Result<Json<AnalyzeResponse>, AppError> {
    let user_id = auth_user.0;

    let voice_record: VoiceRecord = sqlx::query_as(
        r#"
        SELECT id, user_id, file_url, file_key, duration_seconds, transcript, emotion,
               emotion_intensity, voice_features, ai_summary, keywords, risk_level,
               transcription_status, analysis_status, allow_ai_analysis, write_to_emotion_profile,
               created_at, deleted_at
        FROM voice_records
        WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL
        "#
    )
    .bind(record_id)
    .bind(user_id)
    .fetch_optional(&pool)
    .await?
    .ok_or_else(|| AppError::NotFound("Voice record not found".into()))?;

    if voice_record.transcript.is_none() {
        return Err(AppError::BadRequest("Transcript not available. Please transcribe first.".into()));
    }

    sqlx::query("UPDATE voice_records SET analysis_status = 'processing' WHERE id = $1")
        .bind(record_id)
        .execute(&pool)
        .await?;

    let analysis = call_emotion_analysis(
        &config.ai_engine_url,
        &voice_record.transcript.clone().unwrap_or_default(),
    )
    .await?;

    let updated: VoiceRecord = sqlx::query_as(
        r#"
        UPDATE voice_records
        SET emotion = $1, emotion_intensity = $2, keywords = $3, ai_summary = $4,
            risk_level = $5, analysis_status = 'completed'
        WHERE id = $6
        RETURNING id, user_id, file_url, file_key, duration_seconds, transcript, emotion,
                   emotion_intensity, voice_features, ai_summary, keywords, risk_level,
                   transcription_status, analysis_status, allow_ai_analysis, write_to_emotion_profile,
                   created_at, deleted_at
        "#
    )
    .bind(&analysis.emotion)
    .bind(analysis.emotion_intensity)
    .bind(&analysis.keywords)
    .bind(&analysis.ai_summary)
    .bind(&analysis.risk_level)
    .bind(record_id)
    .fetch_one(&pool)
    .await?;

    if updated.write_to_emotion_profile {
        create_emotion_record(&pool, user_id, &analysis, record_id).await?;
    }

    Ok(Json(AnalyzeResponse {
        voice_record: updated,
        emotion: analysis.emotion,
        emotion_intensity: analysis.emotion_intensity,
        keywords: analysis.keywords,
        ai_summary: analysis.ai_summary,
        risk_level: analysis.risk_level,
    }))
}

async fn call_asr(ai_url: &str, file_url: &str) -> Result<String, AppError> {
    let client = reqwest::Client::new();

    let payload = serde_json::json!({
        "file_url": file_url
    });

    let resp = client
        .post(format!("{}/v1/transcribe", ai_url))
        .json(&payload)
        .timeout(std::time::Duration::from_secs(60))
        .send()
        .await?;

    if resp.status().is_success() {
        let data: serde_json::Value = resp.json().await?;
        Ok(data.get("transcript")
            .and_then(|t| t.as_str())
            .unwrap_or("")
            .to_string())
    } else {
        Ok("Transcription service unavailable".to_string())
    }
}

async fn call_emotion_analysis(
    ai_url: &str,
    transcript: &str,
) -> Result<EmotionAnalysisResult, AppError> {
    let client = reqwest::Client::new();

    let payload = serde_json::json!({
        "text": transcript
    });

    let resp = client
        .post(format!("{}/v1/analyze/emotion", ai_url))
        .json(&payload)
        .timeout(std::time::Duration::from_secs(30))
        .send()
        .await?;

    if resp.status().is_success() {
        let data: serde_json::Value = resp.json().await?;
        Ok(EmotionAnalysisResult {
            emotion: data.get("emotion").and_then(|e| e.as_str()).unwrap_or("neutral").to_string(),
            emotion_intensity: data.get("intensity").and_then(|i| i.as_f64()).unwrap_or(0.5),
            keywords: data.get("keywords")
                .and_then(|k| k.as_array())
                .map(|arr| arr.iter().filter_map(|v| v.as_str()).map(String::from).collect())
                .unwrap_or_default(),
            ai_summary: data.get("summary").and_then(|s| s.as_str()).unwrap_or("").to_string(),
            risk_level: data.get("risk_detected").and_then(|r| r.as_bool()).unwrap_or(false)
                .then_some("high").unwrap_or("low").to_string(),
        })
    } else {
        Ok(EmotionAnalysisResult {
            emotion: "neutral".to_string(),
            emotion_intensity: 0.5,
            keywords: vec![],
            ai_summary: "Analysis failed".to_string(),
            risk_level: "low".to_string(),
        })
    }
}

async fn create_emotion_record(
    pool: &PgPool,
    user_id: Uuid,
    analysis: &EmotionAnalysisResult,
    source_id: Uuid,
) -> Result<(), AppError> {
    sqlx::query(
        r#"
        INSERT INTO emotion_records (user_id, emotion, intensity, source, source_id, keywords, ai_summary, risk_detected)
        VALUES ($1, $2, $3, 'voice', $4, $5, $6, $7)
        "#
    )
    .bind(user_id)
    .bind(&analysis.emotion)
    .bind(analysis.emotion_intensity)
    .bind(source_id)
    .bind(&analysis.keywords)
    .bind(&analysis.ai_summary)
    .bind(analysis.risk_level == "high")
    .execute(pool)
    .await?;

    Ok(())
}

#[derive(Debug)]
struct EmotionAnalysisResult {
    emotion: String,
    emotion_intensity: f64,
    keywords: Vec<String>,
    ai_summary: String,
    risk_level: String,
}