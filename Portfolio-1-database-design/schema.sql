### 1. `portfolio-1-database-design/schema.sql`
```sql
-- MIT 8103 Portfolio 1: Relational Schema for NaijaCart Retail Ltd
-- Target Engine: PostgreSQL 17

DROP TABLE IF EXISTS deliveries CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS inventory CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS addresses CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

-- 1. Customers
CREATE TABLE customers (
    customer_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name   TEXT NOT NULL,
    email       TEXT NOT NULL CONSTRAINT uq_customers_email UNIQUE,
    phone       TEXT,
    region      TEXT NOT NULL DEFAULT 'Lagos',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Addresses
CREATE TABLE addresses (
    address_id  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL CONSTRAINT fk_addresses_customer REFERENCES customers(customer_id) ON DELETE CASCADE,
    street      TEXT NOT NULL,
    city        TEXT NOT NULL,
    state       TEXT NOT NULL,
    is_default  BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enforce at most one default address per customer via partial unique index
CREATE UNIQUE INDEX idx_addresses_one_default_per_customer
    ON addresses (customer_id)
    WHERE is_default = TRUE;

-- 3. Categories (Self-referencing hierarchy)
CREATE TABLE categories (
    category_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        TEXT NOT NULL CONSTRAINT uq_categories_name UNIQUE,
    parent_id   BIGINT CONSTRAINT fk_categories_parent REFERENCES categories(category_id) ON DELETE SET NULL
);

-- 4. Products
CREATE TABLE products (
    product_id  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sku         TEXT NOT NULL CONSTRAINT uq_products_sku UNIQUE,
    name        TEXT NOT NULL,
    category_id BIGINT NOT NULL CONSTRAINT fk_products_category REFERENCES categories(category_id) ON DELETE RESTRICT,
    price       NUMERIC(12,2) NOT NULL CONSTRAINT chk_products_price_positive CHECK (price > 0),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. Inventory (1-to-1 with products for stock control)
CREATE TABLE inventory (
    product_id  BIGINT PRIMARY KEY CONSTRAINT fk_inventory_product REFERENCES products(product_id) ON DELETE CASCADE,
    quantity    INTEGER NOT NULL CONSTRAINT chk_inventory_qty_nonnegative CHECK (quantity >= 0),
    version     INTEGER NOT NULL DEFAULT 0,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. Orders
CREATE TABLE orders (
    order_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL CONSTRAINT fk_orders_customer REFERENCES customers(customer_id) ON DELETE RESTRICT,
    status      TEXT NOT NULL DEFAULT 'PENDING'
                CONSTRAINT chk_orders_status CHECK (status IN ('PENDING', 'PAID', 'SHIPPED', 'DELIVERED', 'CANCELLED')),
    placed_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    total       NUMERIC(12,2) NOT NULL DEFAULT 0.00
                CONSTRAINT chk_orders_total_nonnegative CHECK (total >= 0)
);

-- 7. Order Items (Composite Primary Key)
CREATE TABLE order_items (
    order_id    BIGINT NOT NULL CONSTRAINT fk_order_items_order REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id  BIGINT NOT NULL CONSTRAINT fk_order_items_product REFERENCES products(product_id) ON DELETE RESTRICT,
    quantity    INTEGER NOT NULL CONSTRAINT chk_order_items_qty_positive CHECK (quantity > 0),
    unit_price  NUMERIC(12,2) NOT NULL CONSTRAINT chk_order_items_price_positive CHECK (unit_price > 0),
    PRIMARY KEY (order_id, product_id)
);

-- 8. Payments
CREATE TABLE payments (
    payment_id  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id    BIGINT NOT NULL CONSTRAINT fk_payments_order REFERENCES orders(order_id) ON DELETE RESTRICT,
    amount      NUMERIC(12,2) NOT NULL CONSTRAINT chk_payments_amount_positive CHECK (amount > 0),
    method      TEXT NOT NULL CONSTRAINT chk_payments_method CHECK (method IN ('CARD', 'BANK_TRANSFER', 'WALLET')),
    status      TEXT NOT NULL CONSTRAINT chk_payments_status CHECK (status IN ('INITIATED', 'SUCCESS', 'FAILED', 'REVERSED')),
    paid_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 9. Deliveries
CREATE TABLE deliveries (
    delivery_id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id        BIGINT NOT NULL CONSTRAINT uq_deliveries_order UNIQUE
                    CONSTRAINT fk_deliveries_order REFERENCES orders(order_id) ON DELETE CASCADE,
    address_id      BIGINT NOT NULL CONSTRAINT fk_deliveries_address REFERENCES addresses(address_id) ON DELETE RESTRICT,
    tracking_number TEXT NOT NULL CONSTRAINT uq_deliveries_tracking UNIQUE,
    status          TEXT NOT NULL DEFAULT 'PREPARING'
                    CONSTRAINT chk_deliveries_status CHECK (status IN ('PREPARING', 'IN_TRANSIT', 'DELIVERED', 'FAILED')),
    dispatched_at   TIMESTAMPTZ,
    delivered_at    TIMESTAMPTZ
);