# Portfolio 2: Query Processing and Optimisation

## 1. Workload and measurements

I seeded the database with **50,000 customers**, **200 products**, **500,000 orders** and **1,538,156 order items** using `generate_series`, then ran `ANALYZE` (`row-counts.txt`; the database is 219 MB). I ran each query with `EXPLAIN (ANALYZE, BUFFERS)` three times in a row and kept the third run, so the numbers reflect a warm cache rather than cold disk reads. Every figure below comes from a file in `plans/`, and the matching images are in `screenshots/`.

### Query 1: one customer's order history (last 180 days, newest first)
Returns customer 1042's orders from the last 180 days with an item count per order (4 orders, `results/q1.txt`).

**Index added:** `CREATE INDEX idx_orders_customer_placed ON orders (customer_id, placed_at DESC);`

| Stage | Plan | Execution time | Shared buffers |
|---|---|---|---|
| Before | Parallel Seq Scan on `orders`: each of 3 processes discarded 166,665 rows to find customer 1042's orders (4,854 buffers), then Bitmap Heap Scan on `order_items` | 38.48 ms | 4,901 |
| After | Index Scan using `idx_orders_customer_placed` (10 buffers), then **Index Only Scan** using `order_items_pkey` with 0 heap fetches | 0.53 ms | 29 |

That is about 73 times faster and reads 169 times fewer pages. A small Sort node remains in the after-plan, because grouping by `order_id` undoes the index order, but it now sorts 4 rows instead of feeding off a full table scan.

### Query 2: top 10 products by revenue (last 30 days)
Sums `quantity × unit_price` for paid, shipped and delivered orders in the last 30 days: about 24,600 orders and 75,600 order-item rows (`results/q2.txt`).

**Index added:** `CREATE INDEX idx_orders_placed_at ON orders (placed_at) WHERE status IN ('PAID','SHIPPED','DELIVERED');`

| Stage | Plan | Execution time | Shared buffers |
|---|---|---|---|
| Before | Parallel Seq Scan on `orders` (4,854 buffers) hash-joined to a Parallel Seq Scan of all 1.5M `order_items` | 637.8 ms (single run) | 14,021 hit + 2,177 read |
| After | Bitmap Index Scan on `idx_orders_placed_at` (71 buffers), Bitmap Heap Scan on `orders` (still 4,891 buffers), same full scan of `order_items` | 1,457.8 ms (single run) | 14,523 hit + 1,712 read |

**The index did not deliver a clear improvement.** Single runs were too noisy to compare, so I ran the query five more times with the index and five times without it (dropping the index inside a transaction I rolled back): **200–316 ms with it (median 269 ms) and 304–809 ms without it (median 399 ms)** (`plans/q2-repeat-runs.txt`). The index helps a little, for two reasons visible in the plans:

1. **The matching orders are spread across every page.** The index found the 30-day orders in 71 buffers, but fetching those rows still touched 4,891 of the table's pages, more than the 4,854 a full scan reads. `pg_stats` shows a correlation of 0.000 between `placed_at` and physical row order, because my seed script assigned dates at random. A real shop inserts orders in date order, so correlation would be close to 1 and this index would read only the most recent pages. This is a limitation of my synthetic data, not of the index design.
2. **Most of the cost is in `order_items`.** Each run still reads all 1.5 million order items (11,310 buffers) to join them to 24,600 orders.

**What I tried next:**

| Attempt | Result | Evidence |
|---|---|---|
| Covering index `order_items (order_id) INCLUDE (product_id, quantity, unit_price)`, 73 MB | The planner ignored it and kept the full scan (157–567 ms). I dropped it. | `plans/q2-covering-runs.txt` |
| Materialized view `mv_daily_product_sales`: one row per day per product (73,181 rows, 7.4 MB), with a unique index | **6.7–13.8 ms (median 9.3 ms), 643 buffers.** About 43 times faster than the median without an index. | `summary-view.sql`, `q2-summary.sql`, `plans/q2-summary-runs.txt` |

The summary is the right fix for a dashboard query like this one, but it has costs. The data is only as fresh as the last refresh: `REFRESH MATERIALIZED VIEW CONCURRENTLY` took 5.5 s and does not block readers, so an hourly refresh would suit a sales dashboard. It also works in whole days, so it includes the rest of day 30. When I changed the original query to start at midnight 30 days ago, both returned identical top-10 results.

### Query 3: low-stock report (`quantity < 15`)
Joins `inventory` (200 rows), `products` (200 rows) and `categories` (10 rows); 15 products are below the threshold (`results/q3.txt`).

**Index added:** none.

| Stage | Plan | Execution time | Shared buffers |
|---|---|---|---|
| Before | Seq Scan on `inventory` (2 pages, 185 rows filtered out), Hash Join to `products` (3 pages) and `categories` (1 page) | 0.57 ms | 12 |
| After | Identical plan | 0.41 ms | 12 |

## 2. Planner decisions and composite index column order

1. **Seq Scan versus Index Scan (Query 1).** Without an index on `orders (customer_id, placed_at)`, PostgreSQL could only find customer 1042's orders by reading every page of `orders`. Customer 1042 has 11 orders out of 500,000, a selectivity of about 0.002%, so once the index existed a B-tree Index Scan was far cheaper. The planner chose it on its own.
2. **Why `(customer_id, placed_at DESC)` and not `(placed_at, customer_id)`.** In a B-tree the leading column decides how the keys are grouped. Query 1 has an equality condition on `customer_id` and a range plus sort on `placed_at`. With `customer_id` first, all of customer 1042's entries sit in one contiguous range of leaf pages, already in date order, and the index stops at the 180-day boundary. With `placed_at` first, the engine would have to walk every customer's orders in the 180-day range and filter out all but customer 1042's.
3. **Why an index did not rescue Query 2.** An index pays off when it avoids reading most of the table. Query 2 needs about 5% of orders, but they are scattered across every page, and it needs every order item that belongs to them. The planner correctly judged that a hash join over sequential scans was cheaper than about 24,600 separate index lookups. The fix was to change what the query reads (a pre-aggregated summary), not to add more indexes.
4. **Why Query 3 needs no index.** `inventory` and `products` each fit in 2–3 pages of 8 KB. Reading 2 pages in sequence is cheaper than descending a B-tree and then fetching heap pages.

## 3. One index I would NOT add

I would **not** add a standalone B-tree index on `orders (status)`. `status` has only five values, so each value matches about 20% of the table. A query for `status = 'PAID'` would touch almost every page anyway, so the planner would ignore the index and use a Seq Scan, while every `INSERT` and every status `UPDATE` on `orders` would pay to maintain it. My Query 2 index instead uses `status` as a *partial index condition*, which keeps the index small without making `status` a search key.

## How I implemented it
1. Wrote `seed-data.sql` with `generate_series` to create 50,000 customers, 200 products, 500,000 orders and 1,538,156 order items, followed by `ANALYZE`.
2. Wrote the three queries in `queries.sql` (also split into `q1.sql`, `q2.sql` and `q3.sql`) and saved their output to `results/q1.txt`–`results/q3.txt`.
3. Captured the baseline plans `plans/q1-before.txt`–`plans/q3-before.txt` with `EXPLAIN (ANALYZE, BUFFERS)`.
4. Created `idx_orders_customer_placed` and the partial index `idx_orders_placed_at`, ran `ANALYZE orders` (`index-log.txt`), and captured `plans/q1-after.txt`–`plans/q3-after.txt`.
5. Because Query 2 did not improve as expected, timed it five times with and without its index, tested a covering index on `order_items` (then dropped it), and built the materialized view in `summary-view.sql` with the rewritten query in `q2-summary.sql`.

## How I tested it
1. Checked the row counts (`row-counts.txt`): 50,000 customers, 200 products, 500,000 orders, 1,538,156 order items.
2. Ran each `EXPLAIN (ANALYZE, BUFFERS)` three times in a row and kept the third run, so buffer counts show a warm cache.
3. Confirmed in each after-plan that the planner actually used the new index: Index Scan on `idx_orders_customer_placed` for Query 1, Bitmap Index Scan on `idx_orders_placed_at` for Query 2.
4. Repeated Query 2 five times in each configuration, because single timings varied by more than the effect I was measuring.
5. Checked that the materialized view returns the same top 10 as the original query when both use the same whole-day window (`plans/q2-summary-runs.txt`).
