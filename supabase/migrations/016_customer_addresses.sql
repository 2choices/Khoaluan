-- Customer saved addresses
-- Cho phép mỗi customer lưu nhiều địa chỉ giao hàng

CREATE TABLE customer_addresses (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id  UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  tenant_id    UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  label        VARCHAR(50) NOT NULL DEFAULT 'Nhà',
  full_name    VARCHAR(255) NOT NULL,
  phone        VARCHAR(20) NOT NULL,
  address      TEXT NOT NULL,
  city         VARCHAR(100),
  district     VARCHAR(100),
  ward         VARCHAR(100),
  is_default   BOOLEAN NOT NULL DEFAULT false,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_customer_addresses_customer ON customer_addresses(customer_id);
CREATE INDEX idx_customer_addresses_tenant  ON customer_addresses(tenant_id);

-- updated_at trigger
CREATE TRIGGER trg_customer_addresses_updated
  BEFORE UPDATE ON customer_addresses
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Đảm bảo mỗi customer chỉ có 1 địa chỉ mặc định
CREATE OR REPLACE FUNCTION ensure_single_default_address()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.is_default = true THEN
    UPDATE customer_addresses
    SET is_default = false
    WHERE customer_id = NEW.customer_id
      AND id != NEW.id;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_single_default_address
  AFTER INSERT OR UPDATE OF is_default ON customer_addresses
  FOR EACH ROW WHEN (NEW.is_default = true)
  EXECUTE FUNCTION ensure_single_default_address();

-- RLS
ALTER TABLE customer_addresses ENABLE ROW LEVEL SECURITY;

-- Customer app: chỉ xem/sửa địa chỉ của mình (qua user_id → customers.user_id)
CREATE POLICY "customer_addresses_owner" ON customer_addresses
  FOR ALL
  USING (
    customer_id IN (
      SELECT id FROM customers WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    customer_id IN (
      SELECT id FROM customers WHERE user_id = auth.uid()
    )
  );

-- Staff/admin: xem tất cả địa chỉ trong tenant
CREATE POLICY "customer_addresses_staff_read" ON customer_addresses
  FOR SELECT
  USING (
    tenant_id IN (
      SELECT tenant_id FROM employees WHERE user_id = auth.uid() AND is_active = true
    )
  );
