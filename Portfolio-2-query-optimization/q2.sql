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

