-- ============================================
-- OMNIGO Migration 003: Auth & RBAC
-- ============================================

-- Roles table
CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    display_name VARCHAR(100),
    description TEXT,
    is_system BOOLEAN DEFAULT false,  -- owner, manager, cashier, staff
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE UNIQUE INDEX idx_roles_tenant_name ON roles(tenant_id, name);

-- Permissions table
CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(100) UNIQUE NOT NULL,  -- e.g. 'product.create', 'order.view'
    module VARCHAR(50) NOT NULL,         -- e.g. 'product', 'order', 'report'
    action VARCHAR(50) NOT NULL,         -- e.g. 'create', 'read', 'update', 'delete'
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Role-Permission mapping
CREATE TABLE role_permissions (
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

-- Users profile (extends Supabase auth.users)
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES tenant_branches(id) ON DELETE SET NULL,
    full_name VARCHAR(255) NOT NULL,
    avatar_url TEXT,
    phone VARCHAR(20),
    email VARCHAR(255),
    status user_status DEFAULT 'active',
    pin_code VARCHAR(10),  -- quick login PIN for POS
    last_login_at TIMESTAMPTZ,
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_users_tenant ON users(tenant_id);
CREATE INDEX idx_users_branch ON users(branch_id);
CREATE INDEX idx_users_email ON users(email);

-- User-Role mapping
CREATE TABLE user_roles (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES tenant_branches(id) ON DELETE CASCADE,  -- optional: role per branch
    assigned_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (user_id, role_id, COALESCE(branch_id, '00000000-0000-0000-0000-000000000000'))
);

CREATE INDEX idx_user_roles_user ON user_roles(user_id);
CREATE INDEX idx_user_roles_role ON user_roles(role_id);
