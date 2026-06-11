-- ============================================
-- OMNIGO Migration 005: Inventory & Suppliers
-- ============================================

-- Warehouses
CREATE TABLE warehouses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES tenant_branches(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(20),
    address TEXT,
    is_default BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_warehouses_tenant ON warehouses(tenant_id);
CREATE INDEX idx_warehouses_branch ON warehouses(branch_id);

-- Inventory (stock per product_variant per warehouse)
CREATE TABLE inventory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    warehouse_id UUID NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    variant_id UUID REFERENCES product_variants(id) ON DELETE CASCADE,
    quantity DECIMAL(15, 4) DEFAULT 0,
    reserved_quantity DECIMAL(15, 4) DEFAULT 0,  -- reserved for pending orders
    min_quantity DECIMAL(15, 4) DEFAULT 0,       -- low stock alert threshold
    max_quantity DECIMAL(15, 4),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE UNIQUE INDEX idx_inventory_unique ON inventory(warehouse_id, product_id, COALESCE(variant_id, '00000000-0000-0000-0000-000000000000'));
CREATE INDEX idx_inventory_tenant ON inventory(tenant_id);
CREATE INDEX idx_inventory_product ON inventory(product_id);
CREATE INDEX idx_inventory_low_stock ON inventory(tenant_id) WHERE quantity <= min_quantity;

-- Stock Movements (nhập/xuất/chuyển kho)
CREATE TABLE stock_movements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    warehouse_id UUID NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    variant_id UUID REFERENCES product_variants(id) ON DELETE CASCADE,
    movement_type stock_movement_type NOT NULL,
    quantity DECIMAL(15, 4) NOT NULL,  -- positive = in, negative = out
    unit_cost DECIMAL(15, 2),
    reference_type VARCHAR(50),   -- 'order', 'purchase_order', 'transfer', 'stocktake'
    reference_id UUID,
    note TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_stock_movements_tenant ON stock_movements(tenant_id);
CREATE INDEX idx_stock_movements_warehouse ON stock_movements(warehouse_id);
CREATE INDEX idx_stock_movements_product ON stock_movements(product_id);
CREATE INDEX idx_stock_movements_type ON stock_movements(movement_type);
CREATE INDEX idx_stock_movements_date ON stock_movements(created_at);

-- Stock Batches (lô hàng / hạn sử dụng)
CREATE TABLE stock_batches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    warehouse_id UUID NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    variant_id UUID REFERENCES product_variants(id) ON DELETE CASCADE,
    batch_number VARCHAR(100),
    manufacture_date DATE,
    expiry_date DATE,
    quantity DECIMAL(15, 4) DEFAULT 0,
    unit_cost DECIMAL(15, 2),
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_stock_batches_tenant ON stock_batches(tenant_id);
CREATE INDEX idx_stock_batches_expiry ON stock_batches(expiry_date);
CREATE INDEX idx_stock_batches_product ON stock_batches(product_id);

-- Suppliers
CREATE TABLE suppliers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50),
    contact_person VARCHAR(255),
    phone VARCHAR(20),
    email VARCHAR(255),
    address TEXT,
    city VARCHAR(100),
    tax_code VARCHAR(20),
    bank_account VARCHAR(50),
    bank_name VARCHAR(100),
    note TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_suppliers_tenant ON suppliers(tenant_id);

-- Purchase Orders (đơn nhập hàng)
CREATE TABLE purchase_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    supplier_id UUID NOT NULL REFERENCES suppliers(id) ON DELETE RESTRICT,
    warehouse_id UUID NOT NULL REFERENCES warehouses(id) ON DELETE RESTRICT,
    code VARCHAR(50),
    status VARCHAR(20) DEFAULT 'draft',  -- draft, confirmed, receiving, completed, cancelled
    total_amount DECIMAL(15, 2) DEFAULT 0,
    paid_amount DECIMAL(15, 2) DEFAULT 0,
    discount_amount DECIMAL(15, 2) DEFAULT 0,
    note TEXT,
    expected_date DATE,
    received_date DATE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_purchase_orders_tenant ON purchase_orders(tenant_id);
CREATE INDEX idx_purchase_orders_supplier ON purchase_orders(supplier_id);

-- Purchase Order Items
CREATE TABLE purchase_order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    purchase_order_id UUID NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    variant_id UUID REFERENCES product_variants(id) ON DELETE RESTRICT,
    quantity DECIMAL(15, 4) NOT NULL,
    received_quantity DECIMAL(15, 4) DEFAULT 0,
    unit_cost DECIMAL(15, 2) NOT NULL,
    discount DECIMAL(15, 2) DEFAULT 0,
    total DECIMAL(15, 2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_po_items_order ON purchase_order_items(purchase_order_id);
