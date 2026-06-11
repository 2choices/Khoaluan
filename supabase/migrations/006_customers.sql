-- ============================================
-- OMNIGO Migration 006: Customers & CRM
-- ============================================

-- Customer Groups
CREATE TABLE customer_groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    discount_percent DECIMAL(5, 2) DEFAULT 0,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_customer_groups_tenant ON customer_groups(tenant_id);

-- Add FK to product_price_rules
ALTER TABLE product_price_rules
    ADD CONSTRAINT fk_price_rules_customer_group
    FOREIGN KEY (customer_group_id) REFERENCES customer_groups(id) ON DELETE SET NULL;

-- Customers
CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    group_id UUID REFERENCES customer_groups(id) ON DELETE SET NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,  -- linked app user (Customer App)
    code VARCHAR(50),
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    gender VARCHAR(10),
    date_of_birth DATE,
    address TEXT,
    city VARCHAR(100),
    district VARCHAR(100),
    ward VARCHAR(100),
    avatar_url TEXT,
    note TEXT,
    tags TEXT[],

    -- Loyalty
    loyalty_tier loyalty_tier DEFAULT 'bronze',
    loyalty_points INT DEFAULT 0,
    total_spent DECIMAL(15, 2) DEFAULT 0,
    total_orders INT DEFAULT 0,
    last_order_at TIMESTAMPTZ,

    -- Debt
    debt_amount DECIMAL(15, 2) DEFAULT 0,
    debt_limit DECIMAL(15, 2) DEFAULT 0,

    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_customers_tenant ON customers(tenant_id);
CREATE INDEX idx_customers_group ON customers(group_id);
CREATE INDEX idx_customers_phone ON customers(tenant_id, phone);
CREATE INDEX idx_customers_email ON customers(tenant_id, email);
CREATE INDEX idx_customers_name_trgm ON customers USING gin(full_name gin_trgm_ops);
CREATE INDEX idx_customers_loyalty ON customers(tenant_id, loyalty_tier);

-- Loyalty Points Transactions
CREATE TABLE loyalty_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    points INT NOT NULL,  -- positive = earn, negative = redeem
    balance_after INT NOT NULL,
    reference_type VARCHAR(50),  -- 'order', 'refund', 'manual', 'voucher_redeem', 'birthday_bonus'
    reference_id UUID,
    description TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_loyalty_tx_customer ON loyalty_transactions(customer_id);
CREATE INDEX idx_loyalty_tx_tenant ON loyalty_transactions(tenant_id);
CREATE INDEX idx_loyalty_tx_date ON loyalty_transactions(created_at);
