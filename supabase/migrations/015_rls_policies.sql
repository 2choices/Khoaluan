-- ============================================
-- OMNIGO Migration 015: Row Level Security (RLS)
-- Multi-tenant isolation: mỗi tenant chỉ thấy data của mình
-- ============================================

-- ---- Enable RLS on all tables ----
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_units ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_price_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE warehouses ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE payos_webhook_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE vouchers ENABLE ROW LEVEL SECURITY;
ALTER TABLE voucher_usages ENABLE ROW LEVEL SECURITY;
ALTER TABLE promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE promotion_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE cash_book_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE cash_book_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE debt_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE debt_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE media ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE shipping_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_segments ENABLE ROW LEVEL SECURITY;
ALTER TABLE forecasts ENABLE ROW LEVEL SECURITY;
ALTER TABLE anomalies ENABLE ROW LEVEL SECURITY;

-- ============================================
-- TENANT ISOLATION POLICIES
-- Pattern: user can only access rows where tenant_id matches their tenant
-- ============================================

-- ---- Tenants: users can see their own tenant ----
CREATE POLICY tenant_select ON tenants FOR SELECT
    USING (id = get_current_tenant_id());

CREATE POLICY tenant_update ON tenants FOR UPDATE
    USING (id = get_current_tenant_id());

-- ---- Branches ----
CREATE POLICY branches_select ON tenant_branches FOR SELECT
    USING (tenant_id = get_current_tenant_id());

CREATE POLICY branches_insert ON tenant_branches FOR INSERT
    WITH CHECK (tenant_id = get_current_tenant_id());

CREATE POLICY branches_update ON tenant_branches FOR UPDATE
    USING (tenant_id = get_current_tenant_id());

CREATE POLICY branches_delete ON tenant_branches FOR DELETE
    USING (tenant_id = get_current_tenant_id());

-- ---- Generic tenant-scoped policy macro ----
-- For tables with tenant_id column, apply standard CRUD policies

-- Roles
CREATE POLICY roles_tenant ON roles FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- Permissions (global, readable by all authenticated)
CREATE POLICY permissions_select ON permissions FOR SELECT
    USING (true);

-- Role Permissions
CREATE POLICY role_perms_select ON role_permissions FOR SELECT
    USING (role_id IN (SELECT id FROM roles WHERE tenant_id = get_current_tenant_id()));

CREATE POLICY role_perms_modify ON role_permissions FOR ALL
    USING (role_id IN (SELECT id FROM roles WHERE tenant_id = get_current_tenant_id()))
    WITH CHECK (role_id IN (SELECT id FROM roles WHERE tenant_id = get_current_tenant_id()));

-- Users
CREATE POLICY users_tenant ON users FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- User Roles
CREATE POLICY user_roles_tenant ON user_roles FOR ALL
    USING (user_id IN (SELECT id FROM users WHERE tenant_id = get_current_tenant_id()))
    WITH CHECK (user_id IN (SELECT id FROM users WHERE tenant_id = get_current_tenant_id()));

-- Categories
CREATE POLICY categories_tenant ON categories FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- Products
CREATE POLICY products_tenant ON products FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- Product Variants
CREATE POLICY variants_tenant ON product_variants FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- Product Images
CREATE POLICY images_tenant ON product_images FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- Product Units
CREATE POLICY units_tenant ON product_units FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- Product Price Rules
CREATE POLICY price_rules_tenant ON product_price_rules FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- Warehouses
CREATE POLICY warehouses_tenant ON warehouses FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- Inventory
CREATE POLICY inventory_tenant ON inventory FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- Stock Movements
CREATE POLICY stock_movements_tenant ON stock_movements FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- Stock Batches
CREATE POLICY stock_batches_tenant ON stock_batches FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- Suppliers
CREATE POLICY suppliers_tenant ON suppliers FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- Purchase Orders
CREATE POLICY purchase_orders_tenant ON purchase_orders FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- Purchase Order Items (via parent)
CREATE POLICY po_items_tenant ON purchase_order_items FOR ALL
    USING (purchase_order_id IN (SELECT id FROM purchase_orders WHERE tenant_id = get_current_tenant_id()))
    WITH CHECK (purchase_order_id IN (SELECT id FROM purchase_orders WHERE tenant_id = get_current_tenant_id()));

-- Customer Groups
CREATE POLICY customer_groups_tenant ON customer_groups FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- Customers
CREATE POLICY customers_tenant ON customers FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- Loyalty Transactions
CREATE POLICY loyalty_tx_tenant ON loyalty_transactions FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- Shifts
CREATE POLICY shifts_tenant ON shifts FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- Orders
CREATE POLICY orders_tenant ON orders FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- Order Items
CREATE POLICY order_items_tenant ON order_items FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- Payments
CREATE POLICY payments_tenant ON payments FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- PayOS Webhook Logs (service role only for insert, tenant for select)
CREATE POLICY payos_logs_select ON payos_webhook_logs FOR SELECT
    USING (tenant_id = get_current_tenant_id() OR tenant_id IS NULL);

-- Vouchers
CREATE POLICY vouchers_tenant ON vouchers FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- Voucher Usages
CREATE POLICY voucher_usages_tenant ON voucher_usages FOR ALL
    USING (voucher_id IN (SELECT id FROM vouchers WHERE tenant_id = get_current_tenant_id()))
    WITH CHECK (voucher_id IN (SELECT id FROM vouchers WHERE tenant_id = get_current_tenant_id()));

-- Promotions
CREATE POLICY promotions_tenant ON promotions FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- Promotion Rules
CREATE POLICY promo_rules_tenant ON promotion_rules FOR ALL
    USING (promotion_id IN (SELECT id FROM promotions WHERE tenant_id = get_current_tenant_id()))
    WITH CHECK (promotion_id IN (SELECT id FROM promotions WHERE tenant_id = get_current_tenant_id()));

-- Cash Book Categories
CREATE POLICY cashbook_cat_tenant ON cash_book_categories FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- Cash Book Entries
CREATE POLICY cashbook_tenant ON cash_book_entries FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- Debt Records
CREATE POLICY debt_tenant ON debt_records FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- Debt Payments
CREATE POLICY debt_payments_tenant ON debt_payments FOR ALL
    USING (debt_record_id IN (SELECT id FROM debt_records WHERE tenant_id = get_current_tenant_id()))
    WITH CHECK (debt_record_id IN (SELECT id FROM debt_records WHERE tenant_id = get_current_tenant_id()));

-- Employees
CREATE POLICY employees_tenant ON employees FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- Attendance
CREATE POLICY attendance_tenant ON attendance FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- Employee Tasks
CREATE POLICY tasks_tenant ON employee_tasks FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- Media
CREATE POLICY media_tenant ON media FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- Notifications (user can only see their own)
CREATE POLICY notifications_user ON notifications FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY notifications_insert ON notifications FOR INSERT
    WITH CHECK (tenant_id = get_current_tenant_id());

CREATE POLICY notifications_update ON notifications FOR UPDATE
    USING (user_id = auth.uid());

-- Activity Logs
CREATE POLICY activity_tenant ON activity_logs FOR SELECT
    USING (tenant_id = get_current_tenant_id());

CREATE POLICY activity_insert ON activity_logs FOR INSERT
    WITH CHECK (tenant_id = get_current_tenant_id());

-- Settings
CREATE POLICY settings_tenant ON settings FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- Shipping Orders
CREATE POLICY shipping_tenant ON shipping_orders FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- AI: Recommendations
CREATE POLICY recommendations_tenant ON recommendations FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- AI: Customer Segments
CREATE POLICY segments_tenant ON customer_segments FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- AI: Forecasts
CREATE POLICY forecasts_tenant ON forecasts FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- AI: Anomalies
CREATE POLICY anomalies_tenant ON anomalies FOR ALL
    USING (tenant_id = get_current_tenant_id())
    WITH CHECK (tenant_id = get_current_tenant_id());

-- ============================================
-- CUSTOMER APP: Public read policies for products
-- (Customers browsing catalog don't have tenant context)
-- ============================================

-- Products: public read for active products (for Customer App catalog)
CREATE POLICY products_public_read ON products FOR SELECT
    USING (is_active = true);

-- Categories: public read for active categories
CREATE POLICY categories_public_read ON categories FOR SELECT
    USING (is_active = true);

-- Product Variants: public read for active variants
CREATE POLICY variants_public_read ON product_variants FOR SELECT
    USING (is_active = true);

-- Product Images: public read
CREATE POLICY images_public_read ON product_images FOR SELECT
    USING (true);
