-- AI Engine Configuration Seed
-- Note: Prompts are stored in AI Engine config, not database

-- System configuration key-value store
CREATE TABLE IF NOT EXISTS system_config (
    key VARCHAR(100) PRIMARY KEY,
    value TEXT NOT NULL,
    description VARCHAR(500),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default configs
INSERT INTO system_config (key, value, description) VALUES
('llm_provider', 'rules', 'LLM provider: rules or openai_compatible'),
('llm_model', 'gpt-3.5-turbo', 'Default LLM model'),
('asr_provider', 'placeholder', 'ASR provider: placeholder or real'),
('safety_threshold', '0.7', 'Safety check threshold'),
('max_letter_length', '5000', 'Maximum private letter length'),
('max_voice_duration', '300', 'Maximum voice recording duration in seconds'),
('risk_alert_enabled', 'true', 'Enable risk event alerts'),
('default_campus', '未知', 'Default campus for anonymous users');