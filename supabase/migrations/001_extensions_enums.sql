-- ============================================
-- OMNIGO Migration 001: Extensions & Enums
-- ============================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- fuzzy text search

-- ============================================
-- ENUM TYPES
-- ============================================

CREATE TYPE user_status AS ENUM ('active', 'inactive', 'suspended');
CREATE TYPE order_status AS ENUM ('draft', 'pending', 'confirmed', 'processing', 'completed', 'cancelled', 'refunded');
CREATE TYPE payment_status AS ENUM ('pending', 'paid', 'failed', 'refunded', 'partial');
CREATE TYPE payment_method AS ENUM ('cash', 'vietqr', 'bank_transfer', 'split', 'debt');
CREATE TYPE stock_movement_type AS ENUM ('purchase', 'sale', 'return', 'transfer', 'adjustment', 'damage');
CREATE TYPE shift_status AS ENUM ('open', 'closed');
CREATE TYPE debt_type AS ENUM ('customer', 'supplier');
CREATE TYPE debt_status AS ENUM ('pending', 'partial', 'paid');
CREATE TYPE notification_type AS ENUM ('order', 'inventory', 'promotion', 'system', 'ai_alert');
CREATE TYPE loyalty_tier AS ENUM ('bronze', 'silver', 'gold', 'platinum');
CREATE TYPE voucher_type AS ENUM ('percentage', 'fixed_amount', 'free_shipping');
CREATE TYPE voucher_status AS ENUM ('active', 'expired', 'used', 'disabled');
CREATE TYPE promotion_type AS ENUM ('discount', 'bundle', 'flash_sale', 'buy_x_get_y');
CREATE TYPE shipping_status AS ENUM ('pending', 'picking', 'shipping', 'delivered', 'returned', 'cancelled');
CREATE TYPE shipping_provider AS ENUM ('ghn', 'ghtk', 'self');
CREATE TYPE media_bucket AS ENUM ('omnigo-media', 'omnigo-vault', 'omnigo-temp');
CREATE TYPE task_status AS ENUM ('todo', 'in_progress', 'done', 'cancelled');
CREATE TYPE attendance_type AS ENUM ('check_in', 'check_out');
CREATE TYPE cash_book_type AS ENUM ('income', 'expense');
CREATE TYPE order_source AS ENUM ('pos', 'online', 'kiosk');
CREATE TYPE rfm_segment AS ENUM ('champions', 'loyal', 'potential', 'new_customers', 'at_risk', 'lost');
