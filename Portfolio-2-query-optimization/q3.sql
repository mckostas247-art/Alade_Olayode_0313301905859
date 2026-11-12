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
