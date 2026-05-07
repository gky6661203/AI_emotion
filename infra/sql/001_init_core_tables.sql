-- AI Emotion System Database Schema
-- PostgreSQL 17+

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================
-- Users (Anonymous Users)
-- ============================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    anonymous_token VARCHAR(255) UNIQUE NOT NULL,
    nickname VARCHAR(100),
    avatar_url VARCHAR(500),
    campus VARCHAR(200),
    enrollment_year INTEGER,
    risk_level VARCHAR(20) DEFAULT 'low' CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
    state_vector_id UUID,
    total_interactions INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- User State Vector (Emotional Profile)
CREATE TABLE user_state_vectors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    dimension_valence DECIMAL(5,4) DEFAULT 0.5,        -- Emotion valence (-1 ~ 1)
    dimension_arousal DECIMAL(5,4) DEFAULT 0.5,         -- Arousal level (0 ~ 1)
    dimension_dominance DECIMAL(5,4) DEFAULT 0.5,        -- Dominance/Control (0 ~ 1)
    dimension_social DECIMAL(5,4) DEFAULT 0.5,           -- Social need (0 ~ 1)
    dimension_cognitive DECIMAL(5,4) DEFAULT 0.5,       -- Cognitive load (0 ~ 1)
    vector_snapshot JSONB,
    computed_at TIMESTAMPTZ DEFAULT NOW()
);

-- Update users.state_vector_id after insert
CREATE OR REPLACE FUNCTION update_user_state_vector_id()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE users SET state_vector_id = NEW.id WHERE id = NEW.user_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_user_state_vector
    AFTER INSERT ON user_state_vectors
    FOR EACH ROW EXECUTE FUNCTION update_user_state_vector_id();

-- ============================================
-- Devices
-- ============================================
CREATE TABLE devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id VARCHAR(255) UNIQUE NOT NULL,
    device_type VARCHAR(50) CHECK (device_type IN ('phone', 'tablet', 'wearable', 'pc')),
    device_name VARCHAR(200),
    os_version VARCHAR(50),
    app_version VARCHAR(50),
    last_sync_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- Chat Messages
-- ============================================
CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_id UUID,
    role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    content_type VARCHAR(20) DEFAULT 'text' CHECK (content_type IN ('text', 'voice', 'image')),
    message_metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- Emotion Records
-- ============================================
CREATE TABLE emotion_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    emotion VARCHAR(50) NOT NULL,
    intensity DECIMAL(3,2) DEFAULT 0.5 CHECK (intensity >= 0 AND intensity <= 1),
    source VARCHAR(20) CHECK (source IN ('text', 'voice', 'behavior', 'explicit')),
    source_id UUID,
    keywords TEXT[],
    ai_summary TEXT,
    trigger_type VARCHAR(50),
    risk_detected BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- Private Letters (Tree Hole)
-- ============================================
CREATE TABLE private_letters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200),
    content TEXT NOT NULL,
    content_type VARCHAR(20) DEFAULT 'text' CHECK (content_type IN ('text', 'voice', 'handwrite')),
    allow_ai_analysis BOOLEAN DEFAULT true,
    ai_summary TEXT,
    keywords TEXT[],
    emotion VARCHAR(50),
    emotion_intensity DECIMAL(3,2),
    write_to_emotion_profile BOOLEAN DEFAULT true,
    affect_recommendation JSONB,
    affect_matching JSONB,
    open_at TIMESTAMPTZ,
    is_public BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- ============================================
-- Voice Records
-- ============================================
CREATE TABLE voice_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    file_url VARCHAR(500) NOT NULL,
    file_key VARCHAR(255),
    duration_seconds INTEGER,
    transcript TEXT,
    emotion VARCHAR(50),
    emotion_intensity DECIMAL(3,2),
    voice_features JSONB,
    ai_summary TEXT,
    keywords TEXT[],
    risk_level VARCHAR(20) DEFAULT 'low' CHECK (risk_level IN ('low', 'medium', 'high')),
    transcription_status VARCHAR(20) DEFAULT 'pending' CHECK (transcription_status IN ('pending', 'processing', 'completed', 'failed')),
    analysis_status VARCHAR(20) DEFAULT 'pending' CHECK (analysis_status IN ('pending', 'processing', 'completed', 'failed')),
    allow_ai_analysis BOOLEAN DEFAULT true,
    write_to_emotion_profile BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- ============================================
-- Risk Events
-- ============================================
CREATE TABLE risk_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    source VARCHAR(20),
    source_id UUID,
    content_preview TEXT,
    ai_analysis TEXT,
    notification_sent BOOLEAN DEFAULT false,
    handled BOOLEAN DEFAULT false,
    handler_id UUID,
    handled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- Indexes
-- ============================================
CREATE INDEX idx_users_token ON users(anonymous_token) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_risk ON users(risk_level) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_created ON users(created_at DESC);

CREATE INDEX idx_state_vectors_user ON user_state_vectors(user_id);
CREATE INDEX idx_state_vectors_computed ON user_state_vectors(computed_at DESC);

CREATE INDEX idx_devices_user ON devices(user_id) WHERE is_active = true;
CREATE INDEX idx_devices_device_id ON devices(device_id);

CREATE INDEX idx_chat_user ON chat_messages(user_id);
CREATE INDEX idx_chat_session ON chat_messages(session_id);
CREATE INDEX idx_chat_created ON chat_messages(created_at DESC);

CREATE INDEX idx_emotion_user ON emotion_records(user_id);
CREATE INDEX idx_emotion_created ON emotion_records(created_at DESC);
CREATE INDEX idx_emotion_risk ON emotion_records(risk_detected) WHERE risk_detected = true;

CREATE INDEX idx_letters_user ON private_letters(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_letters_public ON private_letters(is_public) WHERE deleted_at IS NULL AND is_public = true;
CREATE INDEX idx_letters_created ON private_letters(created_at DESC);

CREATE INDEX idx_voice_user ON voice_records(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_voice_status ON voice_records(transcription_status, analysis_status);

CREATE INDEX idx_risk_user ON risk_events(user_id);
CREATE INDEX idx_risk_handled ON risk_events(handled) WHERE handled = false;
CREATE INDEX idx_risk_created ON risk_events(created_at DESC);

-- ============================================
-- Updated At Trigger
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- Comments
-- ============================================
COMMENT ON TABLE users IS 'Anonymous user accounts';
COMMENT ON TABLE user_state_vectors IS 'User emotional state profile vectors';
COMMENT ON TABLE devices IS 'User device bindings';
COMMENT ON TABLE chat_messages IS 'Chat message history';
COMMENT ON TABLE emotion_records IS 'Detected emotion events';
COMMENT ON TABLE private_letters IS 'Private tree hole letters';
COMMENT ON TABLE voice_records IS 'Voice recording metadata';
COMMENT ON TABLE risk_events IS 'Safety risk detection events';