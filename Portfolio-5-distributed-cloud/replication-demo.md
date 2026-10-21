# PostgreSQL Streaming Replication Verification Log

## 1. Cluster Startup & `pg_stat_replication` Check on Primary (`Port 5433`)
```bash
docker compose -f portfolio-5-distributed-cloud/docker-compose.replica.yml up -d
docker compose -f portfolio-5-distributed-cloud/docker-compose.replica.yml exec primary psql -U shop -d shop -c "SELECT client_addr, state, sync_state, sent_lsn, write_lsn, replay_lsn FROM pg_stat_replication;"