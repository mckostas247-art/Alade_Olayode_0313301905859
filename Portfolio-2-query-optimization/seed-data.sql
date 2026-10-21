### 1. `portfolio-2-query-optimisation/seed-data.sql`
*(Fixes Lab 2 Bug #2: cleanly resets sequences and populates all parent and child tables to 50k customers, 500k orders, and ~1.5M order items.)*
```sql
-- MIT 8103 Portfolio 2: High-Volume Synthetic Seed Data
-- Resets tables and generates 50,000 customers, 200 products, 500,000 orders, ~1.5M order_items

TRUNCATE TABLE deliveries, payments, order_items, orders, inventory, products, categories, addresses, customers RESTART IDENTITY CASCADE;

-- Drop secondary indexes if re-running so baseline "Before" plans are pure
DROP INDEX IF EXISTS idx_orders_customer_placed;
DROP INDEX IF EXISTS idx_orders_placed_at;
DROP INDEX IF EXISTS idx_order_items_product_id;

-- 1. Seed 10 Categories
INSERT INTO categories (name, parent_id)
SELECT 'Category ' || g, CASE WHEN g > 3 THEN (g % 3) + 1 ELSE NULL END
FROM generate_series(1, 10) AS g;

-- 2. Seed 200 Products
INSERT INTO products (sku, name, category_id, price)
SELECT
    'SKU-' || LPAD(g::text, 4, '0'),
    'Product ' || g,
    ((g - 1) % 10) + 1,
    (( (g * 137) % 950 ) * 1000 + 5000)::numeric(12,2)
FROM generate_series(1, 200) AS g;

-- 3. Seed 200 Inventory rows (some intentionally low stock < 15 for Query 3)
INSERT INTO inventory (product_id, quantity)
SELECT
    g,
    CASE WHEN g <= 15 THEN (g % 10) ELSE 50 + (g * 7) % 500 END
FROM generate_series(1, 200) AS g;

-- 4. Seed 50,000 Customers
INSERT INTO customers (full_name, email, phone, region, created_at)
SELECT
    'Customer ' || g,
    'customer' || g || '@naijacart.test',
    '+23480' || LPAD(g::text, 8, '0'),
    (ARRAY['Lagos', 'Abuja', 'Port Harcourt', 'Kano', 'Ibadan'])[(g % 5) + 1],
    NOW() - ((g % 730) || ' days')::interval
FROM generate_series(1, 50000) AS g;

-- 5. Seed 500,000 Orders across the last 365 days
INSERT INTO orders (customer_id, status, placed_at, total)
SELECT
    ((random() * 49999)::int + 1),
    (ARRAY['PENDING', 'PAID', 'SHIPPED', 'DELIVERED', 'CANCELLED'])[((g % 10) % 5) + 1],
    NOW() - (random() * 365 * 86400) * INTERVAL '1 second',
    ((random() * 250000 + 5000)::numeric(12,2))
FROM generate_series(1, 500000) AS g;

-- 6. Seed ~1,500,000 Order Items (ON CONFLICT DO NOTHING avoids composite PK collisions)
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT
    ((random() * 499999)::int + 1),
    ((random() * 199)::int + 1),
    ((random() * 3)::int + 1),
    ((random() * 150000 + 5000)::numeric(12,2))
FROM generate_series(1, 1550000) AS g
ON CONFLICT (order_id, product_id) DO NOTHING;

ANALYZE;