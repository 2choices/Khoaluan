-- ============================================
-- OMNIGO Migration 013: AI Tables
-- ============================================

-- Product Recommendations
CREATE TABLE recommendations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    recommended_product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    algorithm VARCHAR(50) NOT NULL,  -- 'collaborative_filtering', 'apriori', 'manual'
    score DECIMAL(5, 4),             -- confidence score 0-1
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_recommendations_product ON recommendations(product_id);
CREATE INDEX idx_recommendations_tenant ON recommendations(tenant_id);
CREATE UNIQUE INDEX idx_recommendations_unique ON recommendations(tenant_id, product_id, recommended_product_id, algorithm);

-- Customer Segments (AI-generated)
CREATE TABLE customer_segments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    segment rfm_segment NOT NULL,
    rfm_recency INT,           -- days since last purchase
    rfm_frequency INT,         -- number of purchases
    rfm_monetary DECIMAL(15, 2),  -- total spent
    r_score INT,               -- 1-5
    f_score INT,
    m_score INT,
    clv DECIMAL(15, 2),        -- Customer Lifetime Value
    churn_probability DECIMAL(5, 4),  -- 0-1
    suggested_action TEXT,
    metadata JSONB DEFAULT '{}',
    calculated_at TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_segments_customer ON customer_segments(customer_id);
CREATE INDEX idx_segments_tenant ON customer_segments(tenant_id);
CREATE INDEX idx_segments_segment ON customer_segments(tenant_id, segment);

-- Revenue Forecasts
CREATE TABLE forecasts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES tenant_branches(id) ON DELETE CASCADE,
    forecast_type VARCHAR(50) NOT NULL,  -- 'revenue', 'demand', 'inventory'
    target_date DATE NOT NULL,
    predicted_value DECIMAL(15, 2) NOT NULL,
    lower_bound DECIMAL(15, 2),
    upper_bound DECIMAL(15, 2),
    actual_value DECIMAL(15, 2),    -- filled in after actual data
    algorithm VARCHAR(50),           -- 'prophet', 'arima', 'moving_average'
    accuracy DECIMAL(5, 4),
    metadata JSONB DEFAULT '{}',
    calculated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_forecasts_tenant ON forecasts(tenant_id);
CREATE INDEX idx_forecasts_date ON forecasts(target_date);
CREATE INDEX idx_forecasts_type ON forecasts(tenant_id, forecast_type);

-- Anomalies (bất thường)
CREATE TABLE anomalies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES tenant_branches(id) ON DELETE CASCADE,
    anomaly_type VARCHAR(50) NOT NULL,  -- 'revenue_drop', 'unusual_refund', 'stock_discrepancy'
    severity VARCHAR(20) DEFAULT 'medium',  -- 'low', 'medium', 'high', 'critical'
    title VARCHAR(255) NOT NULL,
    description TEXT,
    entity_type VARCHAR(100),
    entity_id UUID,
    expected_value DECIMAL(15, 2),
    actual_value DECIMAL(15, 2),
    deviation_percent DECIMAL(5, 2),
    is_resolved BOOLEAN DEFAULT false,
    resolved_by UUID REFERENCES users(id),
    resolved_at TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}',
    detected_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_anomalies_tenant ON anomalies(tenant_id);
CREATE INDEX idx_anomalies_type ON anomalies(anomaly_type);
CREATE INDEX idx_anomalies_unresolved ON anomalies(tenant_id) WHERE is_resolved = false;
CREATE INDEX idx_anomalies_severity ON anomalies(tenant_id, severity);
