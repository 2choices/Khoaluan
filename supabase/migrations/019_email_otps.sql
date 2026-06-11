-- ============================================
-- OMNIGO Migration 019: Email OTP Verification
-- ============================================

CREATE TABLE IF NOT EXISTS email_otps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) NOT NULL,
    purpose VARCHAR(50) NOT NULL,
    otp_hash VARCHAR(128) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    attempts INT NOT NULL DEFAULT 0,
    used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_email_otps_lookup
    ON email_otps(email, purpose, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_email_otps_expiry
    ON email_otps(expires_at);
