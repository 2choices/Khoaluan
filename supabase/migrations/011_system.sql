-- ============================================
-- OMNIGO Migration 011: Media, Notifications, System
-- ============================================

-- Media
CREATE TABLE media (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    bucket media_bucket NOT NULL DEFAULT 'omnigo-media',
    file_path TEXT NOT NULL,          -- path in R2 bucket
    file_name VARCHAR(255) NOT NULL,
    file_type VARCHAR(50),            -- mime type
    file_size BIGINT,                 -- bytes
    width INT,
    height INT,
    thumbnail_path TEXT,
    small_path TEXT,
    metadata JSONB DEFAULT '{}',
    uploaded_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_media_tenant ON media(tenant_id);
CREATE INDEX idx_media_bucket ON media(bucket);

-- Notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    type notification_type NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT,
    data JSONB DEFAULT '{}',
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_tenant ON notifications(tenant_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = false;

-- Activity Logs (Audit Trail)
CREATE TABLE activity_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,         -- 'create', 'update', 'delete', 'login', 'export'
    entity_type VARCHAR(100) NOT NULL,    -- 'product', 'order', 'customer', etc.
    entity_id UUID,
    changes JSONB,                        -- {field: {old: x, new: y}}
    ip_address INET,
    user_agent TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_activity_tenant ON activity_logs(tenant_id);
CREATE INDEX idx_activity_user ON activity_logs(user_id);
CREATE INDEX idx_activity_entity ON activity_logs(entity_type, entity_id);
CREATE INDEX idx_activity_action ON activity_logs(action);
CREATE INDEX idx_activity_date ON activity_logs(created_at);

-- Settings (tenant-level config)
CREATE TABLE settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    category VARCHAR(100) NOT NULL,  -- 'general', 'pos', 'payment', 'loyalty', 'invoice', 'tax'
    key VARCHAR(255) NOT NULL,
    value JSONB NOT NULL,
    updated_by UUID REFERENCES users(id),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE UNIQUE INDEX idx_settings_unique ON settings(tenant_id, category, key);
CREATE INDEX idx_settings_tenant ON settings(tenant_id);
