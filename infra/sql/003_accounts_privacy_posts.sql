-- Add account, anonymous profile, privacy settings, and standalone public posts

ALTER TABLE users ADD COLUMN IF NOT EXISTS email VARCHAR(255) UNIQUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255);
ALTER TABLE users ADD COLUMN IF NOT EXISTS account_status VARCHAR(20) DEFAULT 'active';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'users_account_status_check'
    ) THEN
        ALTER TABLE users ADD CONSTRAINT users_account_status_check CHECK (account_status IN ('active', 'disabled', 'pending'));
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS anonymous_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    display_name VARCHAR(100) NOT NULL,
    avatar_url VARCHAR(500),
    bio VARCHAR(300),
    interests TEXT[] DEFAULT '{}',
    campus VARCHAR(200),
    enrollment_year INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_privacy_settings (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    allow_chat_analysis BOOLEAN DEFAULT true,
    allow_letter_analysis BOOLEAN DEFAULT true,
    allow_voice_analysis BOOLEAN DEFAULT true,
    allow_profile_update BOOLEAN DEFAULT true,
    allow_recommendation_use BOOLEAN DEFAULT true,
    allow_match_use BOOLEAN DEFAULT false,
    allow_voice_text_retention BOOLEAN DEFAULT true,
    allow_multi_device_sync BOOLEAN DEFAULT false,
    allow_emotion_reminders BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    anonymous_profile_id UUID REFERENCES anonymous_profiles(id) ON DELETE SET NULL,
    title VARCHAR(200),
    content TEXT NOT NULL,
    topic VARCHAR(100),
    allow_comments BOOLEAN DEFAULT true,
    link_match_request BOOLEAN DEFAULT false,
    ai_summary TEXT,
    keywords TEXT[],
    emotion VARCHAR(50),
    emotion_intensity DECIMAL(3,2),
    risk_level VARCHAR(20) DEFAULT 'low' CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
    moderation_status VARCHAR(20) DEFAULT 'approved' CHECK (moderation_status IN ('pending', 'approved', 'rejected', 'hidden')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS post_reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES public_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reaction_type VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(post_id, user_id, reaction_type)
);

CREATE TABLE IF NOT EXISTS post_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES public_posts(id) ON DELETE CASCADE,
    reporter_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reason VARCHAR(100) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'dismissed', 'actioned')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO anonymous_profiles (user_id, display_name, avatar_url, campus, enrollment_year)
SELECT id, COALESCE(nickname, '匿名同学'), avatar_url, campus, enrollment_year
FROM users
WHERE deleted_at IS NULL
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO user_privacy_settings (user_id)
SELECT id
FROM users
WHERE deleted_at IS NULL
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO public_posts (
    id, user_id, anonymous_profile_id, title, content, allow_comments, ai_summary,
    keywords, emotion, emotion_intensity, risk_level, moderation_status, created_at, deleted_at
)
SELECT
    l.id,
    l.user_id,
    ap.id,
    l.title,
    l.content,
    COALESCE((l.affect_recommendation ->> 'allow_comments')::BOOLEAN, true),
    l.ai_summary,
    l.keywords,
    l.emotion,
    l.emotion_intensity,
    'low',
    'approved',
    l.created_at,
    l.deleted_at
FROM private_letters l
LEFT JOIN anonymous_profiles ap ON ap.user_id = l.user_id
WHERE l.is_public = true
ON CONFLICT (id) DO NOTHING;

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email) WHERE deleted_at IS NULL AND email IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_anonymous_profiles_user ON anonymous_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_privacy_settings_user ON user_privacy_settings(user_id);
CREATE INDEX IF NOT EXISTS idx_public_posts_created ON public_posts(created_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_public_posts_topic ON public_posts(topic) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_public_posts_user ON public_posts(user_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_post_reactions_post ON post_reactions(post_id);
CREATE INDEX IF NOT EXISTS idx_post_reports_post ON post_reports(post_id);

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_anonymous_profiles_updated_at ON anonymous_profiles;
CREATE TRIGGER update_anonymous_profiles_updated_at
    BEFORE UPDATE ON anonymous_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_privacy_settings_updated_at ON user_privacy_settings;
CREATE TRIGGER update_privacy_settings_updated_at
    BEFORE UPDATE ON user_privacy_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_public_posts_updated_at ON public_posts;
CREATE TRIGGER update_public_posts_updated_at
    BEFORE UPDATE ON public_posts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
