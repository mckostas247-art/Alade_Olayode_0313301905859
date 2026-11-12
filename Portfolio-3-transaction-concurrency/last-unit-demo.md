# Concurrency demo: two buyers, one unit in stock

Each demo ran as two `psql` sessions at the same time against the Docker database, on 12 November 2026. Before each one, stock was reset:

```sql
UPDATE inventory SET quantity = 1, version = 0 WHERE product_id = 1;
```

Session 2 started 0.5–1.5 seconds after Session 1, and `pg_sleep` held each transaction open long enough for the two to overlap. Each session recorded `clock_timestamp()` so the order of events can be read from the output.

## Demo A: no lock, absolute write (the bug)
**Transcript:** `last-unit-lost-update.txt` · **Image:** `screenshots/last-unit-lost-update.png`

```sql
BEGIN;
SELECT quantity FROM inventory WHERE product_id = 1;   -- both sessions read 1
SELECT pg_sleep(3);
UPDATE inventory SET quantity = 0 WHERE product_id = 1;
INSERT INTO orders (customer_id, status, total) VALUES (3, 'PAID', 485000.00);  -- customer 4 in Session 2
COMMIT;
```

Session 1 read 1 at 06:16:32.78 and Session 2 read 1 at 06:16:33.81. Both wrote `quantity = 0`, both created an order (500003 and 500004), and both committed. **One unit was sold twice.** Nothing failed, because each session wrote a fixed value based on a read that was already out of date. This is the lost-update problem that the other three approaches prevent.

## Demo B: no lock, relative write
**Transcript:** `last-unit-check-constraint.txt` · **Image:** `screenshots/last-unit-check-constraint.png`

The same race, but each session writes `quantity = quantity - 1`. Both read 1. Session 1's update succeeded. Session 2's `UPDATE` did not use the 1 it had read: an `UPDATE` always works on the latest committed version of the row, which was now 0, so it computed 0 − 1 = −1. `chk_inventory_qty_nonnegative` rejected it. The constraint stopped the oversell even though the application logic was racy.

## Demo C: optimistic locking with a version number
**Transcript:** `last-unit-optimistic.txt` · **Image:** `screenshots/last-unit-optimistic.png`

```sql
SELECT quantity, version FROM inventory WHERE product_id = 1;
UPDATE inventory SET quantity = quantity - 1, version = version + 1
WHERE product_id = 1 AND version = 0;
```

Session 1 read (1, version 0) at 07:02:37.95 and Session 2 read the same (1, version 0) at 07:02:41.48, so both believed the unit was available. Session 1 updated first and got `UPDATE 1`, moving the version to 1. Session 2's update, still expecting version 0, matched no row and returned `UPDATE 0`. The application sees zero rows changed and can retry or report that the item has sold out. No locks were held between the read and the write.

## Demo D: pessimistic locking with `SELECT ... FOR UPDATE`
**Transcript:** `last-unit-for-update.txt` · **Image:** `screenshots/last-unit-for-update.png`

| Time | Session 1 | Session 2 |
|---|---|---|
| 06:16:05.74 | `SELECT ... FOR UPDATE` locks the row, reads 1 | |
| 06:16:08.11 | (sleeping, lock held) | asks for the same row `FOR UPDATE`, **blocks** |
| 06:16:10.75 | decrements to 0, commits | lock granted; reads **0** |

Session 2 waited 2.6 seconds and then saw the committed stock of 0, so it could not sell the unit again. The cost is that waiting: every buyer of a hot product queues behind the current lock holder.
