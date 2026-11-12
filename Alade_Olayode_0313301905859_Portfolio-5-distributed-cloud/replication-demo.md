# Replication and failover log

Both runs were on 12 November 2026 against `docker-compose.replica.yml` (image `bitnamilegacy/postgresql:17`, primary on host port 5433, replica on 5434). The full output is in the two transcript files, and the images are in `screenshots/`.

## Run 1: replication (`replication-demo-output.txt`, `screenshots/replication-demo.png`)

| Step | Node | Result |
|---|---|---|
| Load Portfolio 1 `schema.sql` and `sample-data.sql` | primary | loaded without errors |
| `pg_stat_replication` (as superuser) | primary | one client, `walreceiver`, `streaming`, `async`, sent = replay = `0/306D818`, replay lag 0.004 s |
| `pg_is_in_recovery()` | both | primary `f`, replica `t` |
| Insert order 6, `PAID`, 125,000.00 | primary | written at 06:26:27.542 |
| Read order 6 | replica | present at 06:26:30.197 |
| Insert an order | replica | `ERROR: cannot execute INSERT in a read-only transaction` |

## Run 2: manual failover (`failover-demo-output.txt`, `screenshots/failover-demo.png`)

| Step | Node | Result |
|---|---|---|
| `pg_is_in_recovery()`, last order ID | replica | `t`, 6 |
| `docker stop shop-pg-primary` | primary | stopped |
| Insert an order | replica | still refused: read-only |
| `SELECT pg_promote(wait => true)` | replica | `t` |
| `pg_is_in_recovery()` | replica | `f`: it is now a primary |
| Insert an order | promoted node | accepted, `order_id = 34` |
| Read order 6 | promoted node | still present |

The jump from order 6 to order 34 happens because PostgreSQL WAL-logs sequence values 32 at a time, so the promoted node resumes after the last logged batch.

## Commands
```bash
docker compose -f Alade_Olayode_0313301905859_Portfolio-5-distributed-cloud/docker-compose.replica.yml up -d
docker compose -f Alade_Olayode_0313301905859_Portfolio-5-distributed-cloud/docker-compose.replica.yml exec -e PGPASSWORD=postgrespass primary \
  psql -h 127.0.0.1 -U postgres -d shop -c "SELECT client_addr, state, sync_state, replay_lag FROM pg_stat_replication;"
docker compose -f Alade_Olayode_0313301905859_Portfolio-5-distributed-cloud/docker-compose.replica.yml exec -e PGPASSWORD=shop replica \
  psql -U shop -d shop -c "SELECT pg_is_in_recovery();"
```
