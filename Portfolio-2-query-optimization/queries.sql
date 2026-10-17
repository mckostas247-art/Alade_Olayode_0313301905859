-- MIT 8103 Portfolio 2: Operational & Analytical Queries

-- Query 1: Customer Order History (Orders for customer_id = 1042 in the last 180 days, newest first, with item count)
SELECT
    o.order_id,
    o.placed_at,
    o.status,
    o.total,
    COUNT(oi.product_id) AS item_count
FROM orders o
LEFT JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.customer_id = 1042
  AND o.placed_at >= NOW() - INTERVAL '180 days'
GROUP BY o.order_id, o.placed_at, o.status, o.total
ORDER BY o.placed_at DESC
LIMIT 20;

-- Query 2: Top 10 Products by Revenue in the Last 30 Days
SELECT
    p.product_id,
    p.sku,
    p.name,
    SUM(oi.quantity) AS units_sold,
    SUM(oi.quantity * oi.unit_price) AS revenue_30d
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.placed_at >= NOW() - INTERVAL '30 days'
  AND o.status IN ('PAID', 'SHIPPED', 'DELIVERED')
GROUP BY p.product_id, p.sku, p.name
ORDER BY revenue_30d DESC
LIMIT 10;

-- Query 3: Low-Stock Report (Products with inventory < 15 and their current catalogue details)
SELECT
    p.product_id,
    p.sku,
    p.name,
    c.name AS category_name,
    i.quantity AS stock_on_hand,
    p.price
FROM inventory i
JOIN products p ON p.product_id = i.product_id
JOIN categories c ON c.category_id = p.category_id
WHERE i.quantity < 15
ORDER BY i.quantity ASC, p.product_id ASC;