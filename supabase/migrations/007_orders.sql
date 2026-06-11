-- ============================================
-- OMNIGO Migration 007: Orders & Payments (FULL - ĐÃ TỐI ƯU ĐỒNG BỘ INT)
-- ============================================

-- 1. Tạo các ENUM/TYPE cần thiết (tồn tại thì bỏ qua)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'shift_status') THEN
        CREATE TYPE shift_status AS ENUM ('open', 'closed');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_source') THEN
        CREATE TYPE order_source AS ENUM ('pos', 'online', 'app', 'other');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_status') THEN
        CREATE TYPE order_status AS ENUM (
          'draft', 'confirmed', 'completed', 'cancelled', 'refunded'
        );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_status') THEN
        CREATE TYPE payment_status AS ENUM (
            'pending', 'paid', 'failed', 'refunded'
        );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_method') THEN
        CREATE TYPE payment_method AS ENUM (
            'cash', 'bank', 'credit_card', 'momo', 'zalo_pay', 'vnpay', 'unknown'
        );
    END IF;
END $$;


-- 2. BẢNG SHIFT
CREATE TABLE IF NOT EXISTS shifts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES tenant_branches(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    status shift_status DEFAULT 'open',
    opening_amount DECIMAL(15, 2) DEFAULT 0,
    closing_amount DECIMAL(15, 2),
    expected_amount DECIMAL(15, 2),
    difference DECIMAL(15, 2),
    total_sales DECIMAL(15, 2) DEFAULT 0,
    total_orders INT DEFAULT 0,
    total_refunds DECIMAL(15, 2) DEFAULT 0,
    note TEXT,
    opened_at TIMESTAMPTZ DEFAULT now(),
    closed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_shifts_tenant ON shifts(tenant_id);
CREATE INDEX IF NOT EXISTS idx_shifts_branch ON shifts(branch_id);
CREATE INDEX IF NOT EXISTS idx_shifts_user ON shifts(user_id);
CREATE INDEX IF NOT EXISTS idx_shifts_open ON shifts(tenant_id, status) WHERE status = 'open';


-- 3. BẢNG ORDERS
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES tenant_branches(id) ON DELETE RESTRICT,
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    shift_id UUID REFERENCES shifts(id) ON DELETE SET NULL,
    created_by UUID REFERENCES users(id),

    -- Order info
    order_number VARCHAR(50) NOT NULL,
    source order_source DEFAULT 'pos',
    status order_status DEFAULT 'draft',

    -- Amounts
    subtotal DECIMAL(15, 2) DEFAULT 0,
    discount_amount DECIMAL(15, 2) DEFAULT 0,
    discount_percent DECIMAL(5, 2) DEFAULT 0,
    tax_amount DECIMAL(15, 2) DEFAULT 0,
    shipping_fee DECIMAL(15, 2) DEFAULT 0,
    total_amount DECIMAL(15, 2) DEFAULT 0,
    paid_amount DECIMAL(15, 2) DEFAULT 0,
    change_amount DECIMAL(15, 2) DEFAULT 0,

    -- Payment
    payment_status payment_status DEFAULT 'pending',
    payment_method payment_method,

    -- Voucher
    voucher_id UUID,
    voucher_code VARCHAR(50),
    voucher_discount DECIMAL(15, 2) DEFAULT 0,

    -- Loyalty
    loyalty_points_earned INT DEFAULT 0,
    loyalty_points_used INT DEFAULT 0,

    -- Shipping (for online orders)
    shipping_address TEXT,
    shipping_city VARCHAR(100),
    shipping_district VARCHAR(100),
    shipping_ward VARCHAR(100),
    shipping_phone VARCHAR(20),
    shipping_name VARCHAR(255),
    shipping_note TEXT,

    -- Metadata
    note TEXT,
    internal_note TEXT,
    tags TEXT[],
    is_synced BOOLEAN DEFAULT true,
    synced_at TIMESTAMPTZ,
    offline_id VARCHAR(100),

    -- Refund reference
    is_return BOOLEAN DEFAULT false,
    original_order_id UUID REFERENCES orders(id) ON DELETE SET NULL,

    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_orders_number ON orders(tenant_id, order_number);
CREATE INDEX IF NOT EXISTS idx_orders_tenant ON orders(tenant_id);
CREATE INDEX IF NOT EXISTS idx_orders_branch ON orders(branch_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_shift ON orders(shift_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_orders_date ON orders(tenant_id, created_at);
CREATE INDEX IF NOT EXISTS idx_orders_source ON orders(tenant_id, source);
CREATE INDEX IF NOT EXISTS idx_orders_payment ON orders(tenant_id, payment_status);
CREATE INDEX IF NOT EXISTS idx_orders_offline ON orders(tenant_id, is_synced) WHERE is_synced = false;


-- 4. BẢNG ORDER ITEMS
CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    variant_id UUID REFERENCES product_variants(id) ON DELETE RESTRICT,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    product_name VARCHAR(500) NOT NULL,
    variant_name VARCHAR(255),
    sku VARCHAR(100),
    barcode VARCHAR(100),

    -- ✅ TỐI ƯU QUAN TRỌNG: Đổi từ DECIMAL(15,4) sang INT để xử lý triệt để lỗi ép kiểu đồ họa của Flutter
    quantity INT NOT NULL DEFAULT 1, 
    unit_price DECIMAL(15, 2) NOT NULL,
    cost_price DECIMAL(15, 2) DEFAULT 0,
    discount_amount DECIMAL(15, 2) DEFAULT 0,
    discount_percent DECIMAL(5, 2) DEFAULT 0,
    tax_amount DECIMAL(15, 2) DEFAULT 0,
    total DECIMAL(15, 2) NOT NULL,

    note TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product ON order_items(product_id);
CREATE INDEX IF NOT EXISTS idx_order_items_tenant ON order_items(tenant_id);


-- 5. BẢNG PAYMENTS
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    method payment_method NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    status payment_status DEFAULT 'pending',
    reference_code VARCHAR(100),
    metadata JSONB DEFAULT '{}',
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_payments_order ON payments(order_id);
CREATE INDEX IF NOT EXISTS idx_payments_tenant ON payments(tenant_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_method ON payments(tenant_id, method);


-- 6. BẢNG PAYOS WEBHOOK LOGS
CREATE TABLE IF NOT EXISTS payos_webhook_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE SET NULL,
    order_code VARCHAR(100),
    raw_payload JSONB NOT NULL,
    signature TEXT,
    is_verified BOOLEAN DEFAULT false,
    is_processed BOOLEAN DEFAULT false,
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_payos_logs_order ON payos_webhook_logs(order_code);
CREATE INDEX IF NOT EXISTS idx_payos_logs_date ON payos_webhook_logs(created_at);

-- 7. BỔ SUNG GIÁ TRỊ VÀ TÀI KHOẢN HỆ THỐNG
ALTER TYPE payment_method ADD VALUE IF NOT EXISTS 'vietqr';
ALTER TYPE payment_method ADD VALUE IF NOT EXISTS 'payos';
ALTER TYPE payment_method ADD VALUE IF NOT EXISTS 'bank_transfer';

INSERT INTO users (id, tenant_id, branch_id, full_name, email, status)
VALUES (
    'e2000000-0000-0000-0000-000000000001', 
    'a0000000-0000-0000-0000-000000000001', 
    'b0000000-0000-0000-0000-000000000001', 
    'OMNIGO System Admin',
    'admin@omnigo.vn',
    'active'
)
ON CONFLICT (id) DO NOTHING;