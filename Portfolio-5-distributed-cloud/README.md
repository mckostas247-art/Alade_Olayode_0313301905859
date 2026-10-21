# Portfolio 5: Distributed and Cloud Database Exercise

## 1. Read/Write Splitting: Which Reads Can Go to the Replica Safely?
* **Safe for Asynchronous Read Replicas:** Historical order listings (older than a few minutes), analytical dashboards ("Top 10 products in the last 30 days"), product category browsing, and admin reporting queries can safely route to `replica` (`Port 5434`).
* **Must Remain on the Primary (`Read-Your-Own-Writes`):**
  1. Stock checks inside an active checkout transaction (`SELECT ... FOR UPDATE`).
  2. **Post-payment order confirmation redirect:** Immediately after a buyer pays on the primary, their browser redirects to `/orders/6/confirmation`. Because streaming replication defaults to `async` (`pg_stat_replication.sync_state = async`), routing that immediate read to a replica could hit a 50ms replication lag window and return `404 Order Not Found` or `status = 'PENDING'`, panicking the customer. Post-checkout reads must either query the primary or pass a session LSN token (`pg_last_wal_replay_lsn() >= commit_lsn`).

## 2. What Happens to an In-Flight Order During Primary Failover?
1. **Uncommitted In-Flight Transactions:** If the primary crashes before `COMMIT` finishes writing the WAL record, the promoted replica rolls back the incomplete transaction automatically during WAL recovery. The application receives a connection drop error and prompts the user to retry cleanly.
2. **Just-Committed Transactions under `async` Replication:** If the primary commits at $T_0$ and crashes at $T_1$ before shipping the last WAL segment to the asynchronous standby, that transaction could be lost upon failover (split-brain/lost write). For financial orders, configuring **synchronous replication** (`synchronous_commit = on` with at least one standby) ensures `COMMIT` does not return success to the application until both the primary and standby have flushed the WAL record.

## 3. Placing the MongoDB Catalogue in the Distributed Picture
In the full polyglot cloud architecture, the **MongoDB Product Catalogue (`Portfolio 4`)** runs as a **3-node Replica Set** deployed across three Availability Zones with read preference `secondaryPreferred` for product browsing and search, while the **PostgreSQL Primary + Standby (`Portfolio 5`)** handles transactional checkouts, inventory locks, and payments (`CP`).

## How I implemented it
1. Created `docker-compose.replica.yml` configuring a PostgreSQL 17 primary (`Port 5433`) and streaming replica (`Port 5434`).
2. Started the cluster and verified active WAL streaming via `pg_stat_replication`.
3. Loaded `schema.sql` and `sample-data.sql` onto the primary node.
4. Documented the horizontal sharding, CAP theorem trade-offs, and cloud deployment architecture in `sharding-design.md`.

## How I tested it
1. Verified `SELECT client_addr, state, sync_state FROM pg_stat_replication;` on the primary returned `state = streaming` and `sync_state = async`.
2. Inserted `order_id = 6` (`PAID`, `125000.00`) on the primary (`Port 5433`) and queried `SELECT * FROM orders WHERE order_id = 6;` on the replica (`Port 5434`) within 1 second, confirming the row replicated accurately.
3. Executed `INSERT INTO orders ...` directly against the replica (`Port 5434`) and verified PostgreSQL rejected the write with `ERROR: cannot execute INSERT in a read-only transaction`.