-- Query 2 rewritten against the daily summary (mv_daily_product_sales)
SELECT
    p.product_id,
    p.sku,
    p.name,
    SUM(s.units_sold) AS units_sold,
    SUM(s.revenue)    AS revenue_30d
FROM mv_daily_product_sales s
JOIN products p ON p.product_id = s.product_id
WHERE s.sales_day >= (NOW() - INTERVAL '30 days')::date
GROUP BY p.product_id, p.sku, p.name
ORDER BY revenue_30d DESC
LIMIT 10;
