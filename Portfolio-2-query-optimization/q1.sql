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

