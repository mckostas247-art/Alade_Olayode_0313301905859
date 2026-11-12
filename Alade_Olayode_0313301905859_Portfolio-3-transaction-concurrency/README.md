# Portfolio 3: Transactions and Concurrency Control

Every claim below is backed by a captured transcript in this folder; the matching images are in `screenshots/`. The two-session demos ran as two separate `psql` connections at the same time, with `pg_sleep` and `clock_timestamp()` used to fix and record the order of events.

## 1. Mapping the demonstrations to ACID

| Property | What I showed | Evidence |
|---|---|---|
| **Atomicity** | Placing an order writes `orders`, `order_items` and `payments` and decrements `inventory` in one transaction. In Demo 1 all four changes committed together (stock 5 → 3, version 0 → 1). In Demo 2A the stock update failed on `chk_inventory_qty_nonnegative`, so the `ROLLBACK` also undid the `INSERT INTO orders` that had already succeeded; stock stayed at 1. | `place-order-demo.sql`, `place-order-demo-output.txt` |
| **Consistency** | The schema's rules (`quantity >= 0`, `price > 0`, foreign keys) hold before and after every transaction. In Demo B below, two sessions both believed one unit was available and the database still refused the second sale. | `last-unit-check-constraint.txt`, `../Portfolio-1-database-design/constraint-tests.txt` |
| **Isolation** | Under `READ COMMITTED`, Session 1 read 10 and then 8 inside one transaction, after Session 2 committed a change (a non-repeatable read). Under `REPEATABLE READ`, Session 1 read 8 both times while Session 2 changed the row to 5. | `isolation-demo.sql`, `isolation-demo-output.txt` |
| **Durability** | I killed the database container with `docker kill` (no clean shutdown) and restarted it. The log shows `database system was not properly shut down; automatic recovery in progress` and a WAL redo; committed orders 500003 and 500004 and the inventory row were unchanged afterwards. | `durability-restart.txt` |

## 2. The last unit in stock: four ways two buyers can collide

Stock for product 1 was set to 1 before each demo. Two sessions then tried to buy it at almost the same time. Details are in `last-unit-demo.md`.

| Demo | Approach | What happened |
|---|---|---|
| A | No lock; read stock, then write `quantity = 0` | **Both sessions read 1, both committed, and two orders (500003 and 500004) were created for one unit.** This is a lost update: the second write silently overwrote the first. |
| B | No lock; write `quantity = quantity - 1` | The second session's update would have made stock −1, so `chk_inventory_qty_nonnegative` rejected it. The constraint is the last line of defence. |
| C | Optimistic: `UPDATE ... WHERE version = 0` | Both sessions read stock 1 at version 0. Session 1 updated the row first (`UPDATE 1`) and moved the version to 1. Session 2's update matched no rows (`UPDATE 0`), so the application knows to retry or tell the buyer the item is gone. |
| D | Pessimistic: `SELECT ... FOR UPDATE` | Session 1 locked the row at 06:16:05.74. Session 2 asked for the same lock at 06:16:08.11 and **waited 2.6 seconds** until Session 1 committed at 06:16:10.75, then read the new quantity, 0. |

## 3. Pessimistic versus optimistic locking for a flash sale

* **Pessimistic locking (`SELECT ... FOR UPDATE`)** takes a row-level lock in `FOR UPDATE` mode on the selected `inventory` row (and a `ROW SHARE` lock on the table). Any other transaction that wants to lock or change that row waits until the holder commits or rolls back, as Demo D shows.
* **Optimistic concurrency control (`WHERE version = n`)** takes no lock when reading. It checks at `UPDATE` time that the version has not changed since the read. If it has, the update affects 0 rows and the caller retries or gives up, as Demo C shows.
* **What I would use for a flash sale.** Suppose 5,000 customers press "Buy" at once on a product with 50 units. I would use a single guarded update, `UPDATE inventory SET quantity = quantity - $qty, version = version + 1 WHERE product_id = $id AND quantity >= $qty`, inside a short transaction, and treat `UPDATE 0` as "sold out". It needs one round trip, cannot oversell, and holds the row lock only for the duration of the statement. I would not hold a `FOR UPDATE` lock while waiting for a payment gateway: in Demo D one session waited 2.6 seconds behind a 5-second transaction, and with thousands of buyers on one hot row those waits would queue up and use up the connection pool.

## 4. Why not run everything at `SERIALIZABLE`

`SERIALIZABLE` in PostgreSQL (Serializable Snapshot Isolation) prevents every anomaly, including write skew, but it tracks the rows each transaction reads and aborts transactions with error `40001 serialization_failure` when their combined effect could not have happened in some serial order. Under the contention of a busy shop, many checkouts would fail and every endpoint would need a retry loop. `READ COMMITTED` combined with guarded updates, constraints and targeted `FOR UPDATE` locks keeps stock correct at higher throughput, as the demos above show.

## How I implemented it
1. Wrote `place-order-demo.sql` for an atomic multi-table `COMMIT` and a constraint-triggered `ROLLBACK`, and ran it with statement echo on (`place-order-demo-output.txt`).
2. Ran the four last-unit demos as two concurrent `psql` sessions against the Docker database, resetting stock to 1 before each, and captured both sessions' output (`last-unit-*.txt`).
3. Ran `isolation-demo.sql` across two concurrent sessions at `READ COMMITTED` and then `REPEATABLE READ` (`isolation-demo-output.txt`).
4. Tested durability by killing the database container without a clean shutdown and checking committed rows after recovery (`durability-restart.txt`).

## How I tested it
1. **Commit and rollback:** stock went 5 → 3 after Demo 1. In Demo 2A, ordering 2 units with 1 in stock raised `ERROR: new row for relation "inventory" violates check constraint "chk_inventory_qty_nonnegative"`, and stock was still 1 after `ROLLBACK`.
2. **Lost update:** counted the orders created by Demo A (2) against the stock available (1).
3. **Locking:** compared the timestamps each session recorded in Demo D to confirm that Session 2 was blocked until Session 1 committed.
4. **Isolation:** compared Session 1's two reads at each isolation level: 10 then 8 at `READ COMMITTED`; 8 then 8 at `REPEATABLE READ`.
5. **Durability:** read the same rows before and after a hard kill and restart, and checked the recovery messages in the server log.
