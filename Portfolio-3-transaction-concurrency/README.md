## 1. Mapping Demonstrations to ACID Properties
* **Atomicity (`place-order-demo.sql`):** Order creation inserts rows into `orders`, `order_items`, and `payments` and decrements `inventory`. Under Demo 1 (`COMMIT`), all four operations persist together. Under Demo 2A (`ROLLBACK`), when the inventory update fails on `chk_inventory_qty_nonnegative`, the entire transaction aborts and the preceding `INSERT INTO orders` is undone cleanly.
* **Consistency (`place-order-demo.sql` & `schema.sql`):** Database invariants (`quantity >= 0`, `price > 0`, foreign keys) hold true before and after every transaction. Even if a bug in application code forgets to check stock before issuing an `UPDATE`, the database engine rejects any state that would leave `inventory.quantity < 0`.
* **Isolation (`last-unit-demo.md` & `isolation-demo.sql`):** Demonstrates how concurrent sessions interact under `READ COMMITTED` vs. `REPEATABLE READ`, and how row-level locks (`FOR UPDATE`) isolate stock updates from race conditions.
* **Durability (`place-order-demo.sql`):** Once `COMMIT` returns success, PostgreSQL flushes the Write-Ahead Log (WAL) records to disk, ensuring paid orders and stock decrements survive container restarts.

## 2. Pessimistic (`FOR UPDATE`) vs. Optimistic (`version`) Locking for Flash Sales
* **Pessimistic Locking (`SELECT ... FOR UPDATE`):** Acquires an exclusive row lock (`RowExclusiveLock`) on the `inventory` row before updating. Concurrent transactions targeting the same product block in a queue until the holder commits or rolls back.
* **Optimistic Concurrency Control (`WHERE version = n`):** Acquires no read lock; instead, it verifies at `UPDATE` time that the row's `version` has not changed since it was read. If `UPDATE 0` is returned, the caller retries or aborts.
* **Which I Would Pick for a Flash Sale:** For a flash sale where 5,000 customers simultaneously click "Buy" on a product with **50 units in stock**, I would use an **atomic single-statement guarded update** (`UPDATE inventory SET quantity = quantity - $qty, version = version + 1 WHERE product_id = $id AND quantity >= $qty`) combined with short transaction lifetimes, or **optimistic concurrency control** at the API layer. Holding `SELECT ... FOR UPDATE` locks across network round-trips (while waiting for an external payment gateway webhook) would exhaust PostgreSQL's connection pool as thousands of threads block on the single hot row.

## 3. Why `SERIALIZABLE` Is Not Used Globally
While `SERIALIZABLE` (via Serializable Snapshot Isolation, SSI) prevents all concurrency anomalies including write skew, running an entire e-commerce workload at `SERIALIZABLE` adds SIRead lock tracking overhead on every read query and forces frequent `40001 (serialization_failure)` rollbacks under high contention, requiring retry loops across all endpoints. Using `READ COMMITTED` with targeted `FOR UPDATE` locks or atomic guarded updates achieves exact stock correctness at higher throughput.

## How I implemented it
1. Wrote `place-order-demo.sql` to demonstrate atomic multi-table `COMMIT` and constraint-triggered `ROLLBACK`.
2. Opened two concurrent `psql` terminal sessions (`Session 1` and `Session 2`) to execute the last-unit race condition and `SELECT ... FOR UPDATE` blocking behaviour documented in `last-unit-demo.md`.
3. Wrote and executed `isolation-demo.sql` across both sessions to compare `READ COMMITTED` against `REPEATABLE READ`.

## How I tested it
1. Ran `place-order-demo.sql`: verified stock dropped from `5` to `3` on `COMMIT`, and verified that ordering `2` units when stock was `1` raised `ERROR: new row for relation "inventory" violates check constraint "chk_inventory_qty_nonnegative"` and left stock at `1` after `ROLLBACK`.
2. In two concurrent terminals with `quantity = 1`, ran `BEGIN; SELECT ... FOR UPDATE;` in Session 1 and confirmed Session 2 hung at the prompt until Session 1 committed `quantity = 0`, at which point Session 2 immediately returned `quantity = 0`.
3. In `isolation-demo.sql`, verified that a mid-transaction `SELECT` in Session 1 saw Session 2's committed update under `READ COMMITTED` (`10` → `8`), but continued seeing the original snapshot value (`8` → `8`) under `REPEATABLE READ`.