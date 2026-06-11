-- ============================================
-- OMNIGO Migration 012: Shipping
-- ============================================

CREATE TABLE shipping_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    provider shipping_provider NOT NULL,
    provider_order_code VARCHAR(100),   -- GHN/GHTK tracking code
    status shipping_status DEFAULT 'pending',

    -- Sender
    from_name VARCHAR(255),
    from_phone VARCHAR(20),
    from_address TEXT,
    from_district_id INT,
    from_ward_code VARCHAR(20),

    -- Receiver
    to_name VARCHAR(255),
    to_phone VARCHAR(20),
    to_address TEXT,
    to_district_id INT,
    to_ward_code VARCHAR(20),

    -- Package
    weight INT,           -- gram
    length INT,           -- cm
    width INT,
    height INT,
    cod_amount DECIMAL(15, 2) DEFAULT 0,

    -- Fees
    shipping_fee DECIMAL(15, 2) DEFAULT 0,
    insurance_fee DECIMAL(15, 2) DEFAULT 0,
    cod_fee DECIMAL(15, 2) DEFAULT 0,
    total_fee DECIMAL(15, 2) DEFAULT 0,

    -- Tracking
    expected_delivery_date DATE,
    delivered_at TIMESTAMPTZ,
    tracking_url TEXT,
    provider_response JSONB DEFAULT '{}',

    note TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_shipping_tenant ON shipping_orders(tenant_id);
CREATE INDEX idx_shipping_order ON shipping_orders(order_id);
CREATE INDEX idx_shipping_provider ON shipping_orders(provider);
CREATE INDEX idx_shipping_status ON shipping_orders(status);
CREATE INDEX idx_shipping_tracking ON shipping_orders(provider_order_code);
