-- ============================================
-- OMNIGO Migration 008: Marketing (Vouchers & Promotions)
-- ============================================

-- Vouchers
CREATE TABLE vouchers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    code VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    type voucher_type NOT NULL,
    value DECIMAL(15, 2) NOT NULL,          -- percentage or fixed amount
    max_discount DECIMAL(15, 2),            -- cap for percentage vouchers
    min_order_amount DECIMAL(15, 2) DEFAULT 0,
    usage_limit INT,                         -- total uses allowed
    usage_count INT DEFAULT 0,
    per_customer_limit INT DEFAULT 1,
    status voucher_status DEFAULT 'active',
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,
    applicable_products UUID[],              -- empty = all products
    applicable_categories UUID[],
    applicable_customer_groups UUID[],
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE UNIQUE INDEX idx_vouchers_code ON vouchers(tenant_id, code);
CREATE INDEX idx_vouchers_tenant ON vouchers(tenant_id);
CREATE INDEX idx_vouchers_status ON vouchers(tenant_id, status);
CREATE INDEX idx_vouchers_dates ON vouchers(start_date, end_date);

-- Add FK to orders.voucher_id
ALTER TABLE orders
    ADD CONSTRAINT fk_orders_voucher
    FOREIGN KEY (voucher_id) REFERENCES vouchers(id) ON DELETE SET NULL;

-- Voucher Usage tracking
CREATE TABLE voucher_usages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    voucher_id UUID NOT NULL REFERENCES vouchers(id) ON DELETE CASCADE,
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    discount_amount DECIMAL(15, 2) NOT NULL,
    used_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_voucher_usages_voucher ON voucher_usages(voucher_id);
CREATE INDEX idx_voucher_usages_customer ON voucher_usages(customer_id);

-- Promotions
CREATE TABLE promotions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    type promotion_type NOT NULL,
    is_active BOOLEAN DEFAULT true,
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    priority INT DEFAULT 0,          -- higher = applied first
    max_usage INT,
    usage_count INT DEFAULT 0,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_promotions_tenant ON promotions(tenant_id);
CREATE INDEX idx_promotions_active ON promotions(tenant_id, is_active);
CREATE INDEX idx_promotions_dates ON promotions(start_date, end_date);

-- Promotion Rules
CREATE TABLE promotion_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    promotion_id UUID NOT NULL REFERENCES promotions(id) ON DELETE CASCADE,
    -- Conditions
    condition_type VARCHAR(50) NOT NULL,  -- 'min_amount', 'min_quantity', 'product', 'category', 'customer_group'
    condition_value JSONB NOT NULL,       -- flexible conditions
    -- Actions
    action_type VARCHAR(50) NOT NULL,     -- 'discount_percent', 'discount_fixed', 'free_product', 'bundle_price'
    action_value JSONB NOT NULL,          -- flexible actions
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_promo_rules_promotion ON promotion_rules(promotion_id);
