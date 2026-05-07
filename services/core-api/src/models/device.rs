use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Device {
    pub id: Uuid,
    pub user_id: Uuid,
    pub device_id: String,
    pub device_type: Option<String>,
    pub device_name: Option<String>,
    pub os_version: Option<String>,
    pub app_version: Option<String>,
    pub last_sync_at: Option<DateTime<Utc>>,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BindDeviceRequest {
    pub device_id: String,
    pub device_type: Option<String>,
    pub device_name: Option<String>,
    pub os_version: Option<String>,
    pub app_version: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BindDeviceResponse {
    pub device: Device,
}