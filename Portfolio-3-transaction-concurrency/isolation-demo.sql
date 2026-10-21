-- =========================================================================
-- DEMO 1: READ COMMITTED (Default in PostgreSQL) — Non-Repeatable Read Occurs
-- =========================================================================
-- [Session 1]
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT quantity FROM inventory WHERE product_id = 1; -- Returns 10

-- [Session 2]
BEGIN;
UPDATE inventory SET quantity = 8 WHERE product_id = 1;
COMMIT;

-- [Session 1]
SELECT quantity FROM inventory WHERE product_id = 1; -- Returns 8 (Non-repeatable read!)
COMMIT;

-- =========================================================================
-- DEMO 2: REPEATABLE READ — Snapshot Isolation Prevents Non-Repeatable Read
-- =========================================================================
-- [Session 1]
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT quantity FROM inventory WHERE product_id = 1; -- Returns 8

-- [Session 2]
BEGIN;
UPDATE inventory SET quantity = 5 WHERE product_id = 1;
COMMIT;

-- [Session 1]
SELECT quantity FROM inventory WHERE product_id = 1; -- Still returns 8 (Snapshot preserved!)
COMMIT;