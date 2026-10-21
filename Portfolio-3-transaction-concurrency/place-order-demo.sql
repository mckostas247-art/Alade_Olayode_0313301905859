-- MIT 8103 Portfolio 3: Atomic Order Placement (COMMIT & ROLLBACK Demos)

-- Setup test product (product_id = 1) with stock = 5
UPDATE inventory SET quantity = 5, version = 0 WHERE product_id = 1;
SELECT product_id, quantity, version FROM inventory WHERE product_id = 1;

-- =========================================================================
-- DEMO 1: SUCCESSFUL ORDER PLACEMENT (COMMIT)
-- Customer 1 buys 2 units of Product 1 (Unit Price: 485000.00, Total: 970000.00)
-- =========================================================================
BEGIN;

WITH new_order AS (
    INSERT INTO orders (customer_id, status, placed_at, total)
    VALUES (1, 'PAID', NOW(), 970000.00)
    RETURNING order_id
),
inserted_item AS (
    INSERT INTO order_items (order_id, product_id, quantity, unit_price)
    SELECT order_id, 1, 2, 485000.00 FROM new_order
)
INSERT INTO payments (order_id, amount, method, status)
SELECT order_id, 970000.00, 'CARD', 'SUCCESS' FROM new_order;

UPDATE inventory
SET quantity = quantity - 2,
    version = version + 1,
    updated_at = NOW()
WHERE product_id = 1;

COMMIT;

-- Verify post-commit state: stock is now 3
SELECT product_id, quantity, version FROM inventory WHERE product_id = 1;

-- =========================================================================
-- DEMO 2A: FAILED ORDER PLACEMENT — DATABASE CHECK CONSTRAINT (ROLLBACK)
-- Reset stock to 1, then attempt to buy 2 units -> triggers chk_inventory_qty_nonnegative
-- =========================================================================
UPDATE inventory SET quantity = 1 WHERE product_id = 1;

BEGIN;

INSERT INTO orders (customer_id, status, placed_at, total)
VALUES (2, 'PENDING', NOW(), 970000.00);

-- This decrement results in quantity = -1, violating chk_inventory_qty_nonnegative
UPDATE inventory
SET quantity = quantity - 2
WHERE product_id = 1;

-- Transaction is now aborted; issue ROLLBACK
ROLLBACK;

-- Verify stock remains 1 and no partial order for Customer 2 was persisted
SELECT product_id, quantity FROM inventory WHERE product_id = 1;

-- =========================================================================
-- DEMO 2B: APPLICATION-LEVEL GUARD & EXPLICIT ROLLBACK BY CHOICE
-- =========================================================================
BEGIN;

-- Application inspects available stock first and locks the row
SELECT quantity FROM inventory WHERE product_id = 1 FOR UPDATE;
-- Sees quantity = 1, which is < requested quantity (2); aborts cleanly:
ROLLBACK;