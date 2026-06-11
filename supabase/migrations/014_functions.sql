-- ============================================
-- OMNIGO Migration 014: Functions & Triggers
-- ============================================

-- ---- Auto-update updated_at ----
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOR tbl IN
        SELECT table_name FROM information_schema.columns
        WHERE column_name = 'updated_at'
        AND table_schema = 'public'
    LOOP
        EXECUTE format(
            'CREATE TRIGGER tr_%s_updated_at BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION update_updated_at()',
            tbl, tbl
        );
    END LOOP;
END;
$$;

-- ---- Auto-generate order number ----
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TRIGGER AS $$
DECLARE
    prefix TEXT;
    seq INT;
BEGIN
    IF NEW.order_number IS NULL OR NEW.order_number = '' THEN
        -- Format: HD-YYMMDD-XXXXX
        prefix := 'HD-' || to_char(now(), 'YYMMDD') || '-';
        SELECT COALESCE(MAX(
            CAST(SUBSTRING(order_number FROM LENGTH(prefix) + 1) AS INT)
        ), 0) + 1
        INTO seq
        FROM orders
        WHERE tenant_id = NEW.tenant_id
        AND order_number LIKE prefix || '%';

        NEW.order_number := prefix || LPAD(seq::TEXT, 5, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_orders_number
    BEFORE INSERT ON orders
    FOR EACH ROW
    EXECUTE FUNCTION generate_order_number();

-- ---- Update inventory on stock movement ----
CREATE OR REPLACE FUNCTION update_inventory_on_movement()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO inventory (tenant_id, warehouse_id, product_id, variant_id, quantity)
    VALUES (NEW.tenant_id, NEW.warehouse_id, NEW.product_id, NEW.variant_id, NEW.quantity)
    ON CONFLICT (warehouse_id, product_id, COALESCE(variant_id, '00000000-0000-0000-0000-000000000000'))
    DO UPDATE SET
        quantity = inventory.quantity + NEW.quantity,
        updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_stock_movement_inventory
    AFTER INSERT ON stock_movements
    FOR EACH ROW
    EXECUTE FUNCTION update_inventory_on_movement();

-- ---- Update customer stats on order completion ----
CREATE OR REPLACE FUNCTION update_customer_on_order()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' AND NEW.customer_id IS NOT NULL THEN
        UPDATE customers SET
            total_spent = total_spent + NEW.total_amount,
            total_orders = total_orders + 1,
            last_order_at = now(),
            updated_at = now()
        WHERE id = NEW.customer_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_order_customer_stats
    AFTER UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_customer_on_order();

-- ---- Update shift totals on order ----
CREATE OR REPLACE FUNCTION update_shift_on_order()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' AND NEW.shift_id IS NOT NULL THEN
        UPDATE shifts SET
            total_sales = total_sales + NEW.total_amount,
            total_orders = total_orders + 1
        WHERE id = NEW.shift_id;
    END IF;

    IF NEW.status = 'refunded' AND OLD.status != 'refunded' AND NEW.shift_id IS NOT NULL THEN
        UPDATE shifts SET
            total_refunds = total_refunds + NEW.total_amount
        WHERE id = NEW.shift_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_order_shift_stats
    AFTER UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_shift_on_order();

-- ---- Update voucher usage count ----
CREATE OR REPLACE FUNCTION update_voucher_usage()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE vouchers SET
        usage_count = usage_count + 1,
        updated_at = now()
    WHERE id = NEW.voucher_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_voucher_usage
    AFTER INSERT ON voucher_usages
    FOR EACH ROW
    EXECUTE FUNCTION update_voucher_usage();

-- ---- Auto-update debt remaining amount ----
CREATE OR REPLACE FUNCTION update_debt_on_payment()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE debt_records SET
        paid_amount = paid_amount + NEW.amount,
        remaining_amount = remaining_amount - NEW.amount,
        status = CASE
            WHEN remaining_amount - NEW.amount <= 0 THEN 'paid'::debt_status
            WHEN paid_amount + NEW.amount > 0 THEN 'partial'::debt_status
            ELSE status
        END,
        updated_at = now()
    WHERE id = NEW.debt_record_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_debt_payment
    AFTER INSERT ON debt_payments
    FOR EACH ROW
    EXECUTE FUNCTION update_debt_on_payment();

-- ---- Helper: Get current user's tenant_id ----
CREATE OR REPLACE FUNCTION get_current_tenant_id()
RETURNS UUID AS $$
BEGIN
    RETURN (
        SELECT tenant_id FROM users
        WHERE id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ---- Helper: Check if user has permission ----
CREATE OR REPLACE FUNCTION user_has_permission(p_permission_code TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM user_roles ur
        JOIN role_permissions rp ON rp.role_id = ur.role_id
        JOIN permissions p ON p.id = rp.permission_id
        WHERE ur.user_id = auth.uid()
        AND p.code = p_permission_code
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
