-- ============================================
-- Auth Improvements Migration
-- ============================================

-- 1. Add new columns to users table
ALTER TABLE users 
ADD COLUMN phone VARCHAR(255) UNIQUE,
ADD COLUMN is_anonymous BOOLEAN DEFAULT false,
ADD COLUMN login_failures INTEGER DEFAULT 0,
ADD COLUMN locked_until TIMESTAMPTZ,
ADD COLUMN role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('user', 'admin', 'anonymous'));

-- 2. Verification Codes Table
CREATE TABLE verification_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    target VARCHAR(255) NOT NULL, -- email or phone
    code VARCHAR(10) NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('register', 'login', 'reset_password')),
    expires_at TIMESTAMPTZ NOT NULL,
    used BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Third-party Logins Table
CREATE TABLE third_party_logins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider VARCHAR(50) NOT NULL CHECK (provider IN ('wechat', 'qq', 'weibo')),
    provider_id VARCHAR(255) NOT NULL,
    provider_data JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(provider, provider_id)
);

-- 4. Refresh Tokens Table (for JWT)
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(500) UNIQUE NOT NULL,
    device_info VARCHAR(255),
    expires_at TIMESTAMPTZ NOT NULL,
    revoked BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_verification_codes_target ON verification_codes(target, type, used);
CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id, revoked);
