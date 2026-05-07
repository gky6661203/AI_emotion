use reqwest::Client;
use serde_json::Value;

pub struct AIClient {
    client: Client,
    base_url: String,
}

impl AIClient {
    pub fn new(base_url: &str) -> Self {
        Self {
            client: Client::new(),
            base_url: base_url.to_string(),
        }
    }

    pub async fn chat_completion(&self, message: &str) -> Result<String, reqwest::Error> {
        let payload = serde_json::json!({
            "message": message
        });

        let resp = self.client
            .post(format!("{}/v1/chat/completion", self.base_url))
            .json(&payload)
            .timeout(std::time::Duration::from_secs(30))
            .send()
            .await?;

        if resp.status().is_success() {
            let data: Value = resp.json().await?;
            Ok(data.get("content")
                .and_then(|c| c.as_str())
                .unwrap_or("")
                .to_string())
        } else {
            Ok("AI service unavailable".to_string())
        }
    }

    pub async fn analyze_emotion(&self, text: &str) -> Result<Value, reqwest::Error> {
        let payload = serde_json::json!({
            "text": text
        });

        let resp = self.client
            .post(format!("{}/v1/analyze/emotion", self.base_url))
            .json(&payload)
            .timeout(std::time::Duration::from_secs(30))
            .send()
            .await?;

        resp.json().await
    }

    pub async fn transcribe(&self, file_url: &str) -> Result<String, reqwest::Error> {
        let payload = serde_json::json!({
            "file_url": file_url
        });

        let resp = self.client
            .post(format!("{}/v1/transcribe", self.base_url))
            .json(&payload)
            .timeout(std::time::Duration::from_secs(60))
            .send()
            .await?;

        if resp.status().is_success() {
            let data: Value = resp.json().await?;
            Ok(data.get("transcript")
                .and_then(|t| t.as_str())
                .unwrap_or("")
                .to_string())
        } else {
            Ok("Transcription service unavailable".to_string())
        }
    }
}