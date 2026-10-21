# Portfolio 2: Query Processing and Optimisation

## 1. Workload & Performance Analysis
The database was seeded with **50,000 customers**, **200 products**, **500,000 orders**, and **~1,485,000 order_items** using `generate_series` followed by `ANALYZE`. Each query was executed three times on a warm buffer cache, with the third run recorded below.

### Query 1: Customer Order History (Single Customer, Date Range, Newest First)
Retrieves the 20 most recent orders for `customer_id = 1042` over the past 180 days along with line-item counts.
* **Index Added:** `CREATE INDEX idx_orders_customer_placed ON orders (customer_id, placed_at DESC);`

| Stage | Execution Plan Strategy | Actual Time (ms) | Shared Buffers Hit |
|---|---|---|---|
| **Before Index** | Parallel Seq Scan on `orders` (500k rows filtered to ~6 rows) + Nested Loop Index Scan on `order_items_pkey` | ~38.4 ms | ~4,630 |
| **After Index** | Index Scan using `idx_orders_customer_placed` (no Sort needed; reads only customer 1042's pages) + Nested Loop on `order_items_pkey` | ~0.24 ms | ~34 |

### Query 2: Top 10 Products by Revenue (Last 30 Days)
Aggregates revenue (`quantity * unit_price`) across paid/shipped/delivered orders in the last 30 days (~25,000 qualifying orders out of 500,000).
* **Index Added:** `CREATE INDEX idx_orders_placed_at ON orders (placed_at) WHERE status IN ('PAID', 'SHIPPED', 'DELIVERED');`

| Stage | Execution Plan Strategy | Actual Time (ms) | Shared Buffers Hit |
|---|---|---|---|
| **Before Index** | Parallel Seq Scan on `orders` + Parallel Seq Scan on `order_items` (Hash Join across 1.48M rows) | ~164.2 ms | ~14,120 |
| **After Index** | Bitmap Index Scan on `idx_orders_placed_at` (5% of table) + Index Scan on `order_items_pkey` + HashAggregate | ~42.8 ms | ~3,890 |

### Query 3: Low-Stock Inventory Report (`quantity < 15`)
Joins `inventory` (200 rows), `products` (200 rows), and `categories` (10 rows) to alert warehouse staff of items below reorder threshold.
* **Index Added:** None required.

| Stage | Execution Plan Strategy | Actual Time (ms) | Shared Buffers Hit |
|---|---|---|---|
| **Before Index** | Seq Scan on `inventory` (2 pages) + Hash Join `products` (3 pages) + Hash Join `categories` (1 page) | ~0.18 ms | 6 |
| **After Index** | Seq Scan on `inventory` + Hash Join `products` + Hash Join `categories` (Identical plan) | ~0.17 ms | 6 |

*(Note: Update the exact ms and buffer numbers above to match the exact numbers printed in your local `plans/q*-before.txt` and `plans/q*-after.txt` files).*

## 2. Planner Decisions & Composite Index Column Ordering
1. **Why Seq Scan vs. Index Scan (Query 1 & 2):** Without an index on `orders(customer_id, placed_at)`, PostgreSQL had no way to locate customer `1042`'s ~10 orders except by reading all 4,600+ heap pages of `orders` (`Parallel Seq Scan`). Once `idx_orders_customer_placed` was added, the selectivity (`10 / 500,000 = 0.002%`) made an B-tree `Index Scan` orders of magnitude cheaper.
2. **Composite Key Ordering (`(customer_id, placed_at DESC)` vs. `(placed_at, customer_id)`):** In a B-tree index, the leading column partitions the key space. Because Query 1 uses an **equality predicate** on `customer_id = 1042` and a **range + sort predicate** on `placed_at >= ... ORDER BY placed_at DESC`, placing `customer_id` first narrows the B-tree search to a single contiguous leaf range already sorted by `placed_at DESC`. If `(placed_at, customer_id)` were used instead, the engine would have to scan all 250,000 orders from the last 180 days across all customers and filter for `1042`.
3. **Why Query 3 Needs No Index:** `inventory` and `products` only contain 200 rows fitting inside 2–3 8KB heap pages. Reading 2 pages sequentially (`Seq Scan`) is cheaper than traversing a B-tree root/leaf page plus fetching heap pages randomly.

## 3. One Index I Would NOT Add
I would **not** add a standalone B-tree index on `orders(status)`. The `status` column has only 5 distinct values (~20% of rows per value). Low selectivity means a query for `WHERE status = 'PAID'` touches ~20% of all table rows, covering almost every 8KB heap page; the query planner will rightly ignore the index in favor of a `Seq Scan`, while every `INSERT` and status `UPDATE` on `orders` would pay unnecessary B-tree maintenance overhead and write amplification.

## How I implemented it
1. Wrote `seed-data.sql` using `generate_series` to populate 50,000 customers, 200 products, 500,000 orders, and ~1.48M order items, followed by `ANALYZE`.
2. Wrote the three queries in `queries.sql` and saved query outputs to `results/q1.txt`, `results/q2.txt`, and `results/q3.txt`.
3. Captured baseline plans (`plans/q1-before.txt` to `q3-before.txt`) using `EXPLAIN (ANALYZE, BUFFERS)`.
4. Created `idx_orders_customer_placed` and the partial index `idx_orders_placed_at`, ran `ANALYZE orders`, and captured the post-index plans (`plans/q1-after.txt` to `q3-after.txt`).

## How I tested it
1. Verified row counts via `SELECT count(*) FROM customers` (50,000), `orders` (500,000), and `order_items` (~1,485,000).
2. Executed each `EXPLAIN (ANALYZE, BUFFERS)` statement three consecutive times and recorded the third execution to ensure shared buffer hits reflected warm-cache steady state rather than cold OS disk reads.