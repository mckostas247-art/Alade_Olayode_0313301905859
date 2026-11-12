-- Pre-aggregated daily sales per product, for the Query 2 dashboard
CREATE MATERIALIZED VIEW mv_daily_product_sales AS
SELECT
    o.placed_at::date               AS sales_day,
    oi.product_id,
    SUM(oi.quantity)                AS units_sold,
    SUM(oi.quantity * oi.unit_price) AS revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status IN ('PAID', 'SHIPPED', 'DELIVERED')
GROUP BY o.placed_at::date, oi.product_id;

CREATE UNIQUE INDEX idx_mv_daily_product_sales ON mv_daily_product_sales (sales_day, product_id);
