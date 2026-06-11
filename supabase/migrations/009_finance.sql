-- ============================================
-- OMNIGO Migration 009: Finance (Cash Book & Debt)
-- ============================================

-- Cash Book Categories
CREATE TABLE cash_book_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type cash_book_type NOT NULL,
    is_system BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_cashbook_cat_tenant ON cash_book_categories(tenant_id);

-- Cash Book Entries (phiếu thu / phiếu chi)
CREATE TABLE cash_book_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES tenant_branches(id) ON DELETE RESTRICT,
    category_id UUID REFERENCES cash_book_categories(id) ON DELETE SET NULL,
    type cash_book_type NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    description TEXT,
    reference_type VARCHAR(50),  -- 'order', 'purchase_order', 'salary', 'manual'
    reference_id UUID,
    payment_method payment_method,
    created_by UUID REFERENCES users(id),
    entry_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_cashbook_tenant ON cash_book_entries(tenant_id);
CREATE INDEX idx_cashbook_branch ON cash_book_entries(branch_id);
CREATE INDEX idx_cashbook_date ON cash_book_entries(entry_date);
CREATE INDEX idx_cashbook_type ON cash_book_entries(tenant_id, type);

-- Debt Records
CREATE TABLE debt_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    type debt_type NOT NULL,
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    supplier_id UUID REFERENCES suppliers(id) ON DELETE SET NULL,
    amount DECIMAL(15, 2) NOT NULL,
    paid_amount DECIMAL(15, 2) DEFAULT 0,
    remaining_amount DECIMAL(15, 2) NOT NULL,
    status debt_status DEFAULT 'pending',
    reference_type VARCHAR(50),  -- 'order', 'purchase_order'
    reference_id UUID,
    due_date DATE,
    note TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_debt_tenant ON debt_records(tenant_id);
CREATE INDEX idx_debt_customer ON debt_records(customer_id);
CREATE INDEX idx_debt_supplier ON debt_records(supplier_id);
CREATE INDEX idx_debt_status ON debt_records(tenant_id, status);
CREATE INDEX idx_debt_due ON debt_records(due_date) WHERE status != 'paid';

-- Debt Payments
CREATE TABLE debt_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    debt_record_id UUID NOT NULL REFERENCES debt_records(id) ON DELETE CASCADE,
    amount DECIMAL(15, 2) NOT NULL,
    payment_method payment_method,
    note TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_debt_payments_record ON debt_payments(debt_record_id);
