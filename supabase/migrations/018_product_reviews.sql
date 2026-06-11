-- Product reviews table
CREATE TABLE IF NOT EXISTS product_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  rating SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  title TEXT,
  comment TEXT,
  is_visible BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_product_reviews_product ON product_reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_product_reviews_tenant ON product_reviews(tenant_id);
CREATE INDEX IF NOT EXISTS idx_product_reviews_customer ON product_reviews(customer_id);
-- One review per (customer, product, order)
CREATE UNIQUE INDEX IF NOT EXISTS uniq_review_per_order_product
  ON product_reviews(order_id, product_id, customer_id)
  WHERE order_id IS NOT NULL AND customer_id IS NOT NULL;

ALTER TABLE product_reviews ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "tenant isolation reviews" ON product_reviews;
CREATE POLICY "tenant isolation reviews" ON product_reviews
  USING (true)
  WITH CHECK (true);
