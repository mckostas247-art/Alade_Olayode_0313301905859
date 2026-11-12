# Portfolio 5: Distributed and Cloud Database Exercise

I ran a PostgreSQL 17 primary (host port 5433) and a streaming replica (host port 5434) with `docker-compose.replica.yml`, then tested replication, read-only behaviour and a manual failover. Transcripts: `replication-demo-output.txt` and `failover-demo-output.txt`; images in `screenshots/`. The scaling design is in `sharding-design.md`.

## 1. Read/write splitting: which reads can go to the replica?

`pg_stat_replication` on the primary showed the replica as `state = streaming`, `sync_state = async`, with a replay lag of about 4 ms at the time of the test. "Async" means the primary does not wait for the replica before confirming a commit, so the replica can be briefly behind.

* **Safe on the replica:** order history older than a few minutes, the "top 10 products in the last 30 days" dashboard (Portfolio 2, Query 2), category and product browsing, and admin reports. A few milliseconds of staleness does not change any of these answers.
* **Must stay on the primary:**
  1. Stock checks and updates during checkout. These must see the latest committed stock and take row locks (Portfolio 3), and the replica refuses writes anyway (`ERROR: cannot execute INSERT in a read-only transaction`).
  2. **The order confirmation page right after payment.** The buyer's order is written on the primary and the browser immediately loads `/orders/6/confirmation`. If that read goes to an async replica that has not yet replayed the commit, the buyer sees "order not found" or an old status straight after paying. The app should either read its own writes from the primary for a short period after any write, or record the commit's WAL position (`pg_current_wal_lsn()`) and only use the replica once its `pg_last_wal_replay_lsn()` has caught up to it.

## 2. What happens to an in-flight order during a primary failover?

In `failover-demo-output.txt` I stopped the primary with `docker stop`, confirmed the replica still refused writes, promoted it with `SELECT pg_promote()`, and then wrote a new order to it successfully. Order 6, committed before the failover, was still there.

1. **Transactions not yet committed** when the primary dies are lost. Their changes were never committed, so the replica never treats them as committed, and the application gets a connection error and must retry. This is safe as long as the retry cannot create a duplicate order, for example by sending an idempotency key with each checkout.
2. **Transactions committed on the primary but not yet sent to an async replica are lost on failover.** The buyer was told "payment successful", but the order is not on the promoted node. This is **data loss**, not split-brain. Split-brain is a different failure: the old primary comes back and keeps accepting writes while the promoted replica does too, so the two diverge. Preventing it needs fencing, meaning the old primary must be stopped or blocked before the replica is promoted, as `docker stop` did in my test.
3. **To prevent the data loss** for orders and payments, replication must be made synchronous by naming the standby in `synchronous_standby_names` (for example `'FIRST 1 (replica1)'`) on the primary. `synchronous_commit = on` is the default, but on its own it only waits for the primary's local WAL flush; it waits for the standby only when a synchronous standby is named. The cost is that every commit waits for a network round trip, and commits stop if the only synchronous standby is down.
4. **Order numbers can jump after failover.** The first order written on the promoted replica received `order_id = 34`, not 7. PostgreSQL logs sequence values in batches of 32 ahead of use, so a promoted replica continues from the end of the last logged batch. Nothing in the application should assume order IDs have no gaps.

## 3. Where the MongoDB catalogue fits

The MongoDB product catalogue (Portfolio 4) would run as a three-node replica set spread across three availability zones, with read preference `secondaryPreferred` for browsing and search, so it stays available if one node is lost. The PostgreSQL primary and its standby handle checkout, stock and payments, where consistency comes first. `sharding-design.md` sets out the CAP classification for each part.

## How I implemented it
1. Wrote `docker-compose.replica.yml` with a PostgreSQL 17 primary (port 5433) and streaming replica (port 5434). The `bitnami/postgresql` images have been withdrawn from Docker Hub, so the file uses `bitnamilegacy/postgresql:17`. I also set a password for the `postgres` superuser on the primary, because reading the full `pg_stat_replication` view and calling `pg_promote()` both require superuser rights.
2. Started both nodes, loaded `../Alade_Olayode_0313301905859_Portfolio-1-database-design/schema.sql` and `../Alade_Olayode_0313301905859_Portfolio-1-database-design/sample-data.sql` on the primary, and checked the replication status.
3. Wrote on the primary and read on the replica, then attempted a write on the replica.
4. Ran a manual failover: stopped the primary and promoted the replica.
5. Wrote the scaling design in `sharding-design.md`.

## How I tested it
1. `SELECT client_addr, application_name, state, sync_state, sent_lsn, replay_lsn, replay_lag FROM pg_stat_replication;` on the primary returned `streaming`, `async`, equal sent and replay positions, and a replay lag of 0.004 s.
2. `pg_is_in_recovery()` returned `f` on the primary and `t` on the replica.
3. Inserted order 6 (`PAID`, 125,000.00) on the primary at 06:26:27.542 and read it on the replica at 06:26:30.197.
4. An `INSERT` on the replica failed with `ERROR: cannot execute INSERT in a read-only transaction`.
5. Failover: with the primary stopped the replica still refused writes; after `pg_promote()`, `pg_is_in_recovery()` returned `f`, a new order was accepted (ID 34), and order 6 was still present.

To rebuild a clean primary and replica after the failover test:
```bash
docker compose -f Alade_Olayode_0313301905859_Portfolio-5-distributed-cloud/docker-compose.replica.yml down
docker compose -f Alade_Olayode_0313301905859_Portfolio-5-distributed-cloud/docker-compose.replica.yml up -d
```
