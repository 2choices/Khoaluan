-- Extend payment_method enum to support online gateways
-- (payos uses VietQR, but we keep it as a distinct value for clarity)
ALTER TYPE payment_method ADD VALUE IF NOT EXISTS 'payos';
ALTER TYPE payment_method ADD VALUE IF NOT EXISTS 'momo';
ALTER TYPE payment_method ADD VALUE IF NOT EXISTS 'vnpay';
ALTER TYPE payment_method ADD VALUE IF NOT EXISTS 'credit';
