-- ============================================
-- OMNIGO Migration 020: Email OTP Rate Limit by IP
-- ============================================

ALTER TABLE IF EXISTS email_otps
    ADD COLUMN IF NOT EXISTS request_ip VARCHAR(64);

CREATE INDEX IF NOT EXISTS idx_email_otps_ip_created
    ON email_otps(request_ip, created_at DESC)
    WHERE request_ip IS NOT NULL;
