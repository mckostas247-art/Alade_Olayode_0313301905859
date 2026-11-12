# Distributed Architecture & Sharding Design for NaijaCart Retail Ltd

## 1. Horizontal Sharding Strategy
As NaijaCart scales beyond a single primary node's write throughput (e.g., 50M+ orders across Nigeria), tables are classified into **Sharded Tables** and **Reference (Global) Tables**:

* **Shard Key Selection (`customer_id` Hash Sharding):**
  * **Sharded Tables:** `customers`, `addresses`, `orders`, `order_items`, `payments`, and `deliveries` are co-located on shards partitioned by `HASH(customer_id) % N` (or via Citus distributed tables on `customer_id`, adding `customer_id` to child tables).
  * **Why `customer_id` Hash Beats Geographic/Region Sharding:** Order volume is not spread evenly across Nigeria: a large share comes from Lagos and other big cities. Range or list sharding by `region` would therefore create a **hot shard** on the Lagos node while shards for quieter regions sit under-used, and rebalancing would mean splitting a region. Hashing `customer_id` distributes write load evenly across all shards and ensures that a customer's entire order history (`Portfolio 2, Query 1`) executes locally on a **single shard** without cross-node joins.
* **Global Reference Tables:** `categories` and `products` (small, read-heavy tables) are replicated synchronously to all shards so joins between `order_items` and `products` happen locally on each shard.
* **Cross-Shard Aggregations ("Top 10 Products This Month"):** Executed via **Scatter-Gather**: the coordinator sends the partial `SUM(quantity * unit_price) GROUP BY product_id` query to all shards in parallel, merges the intermediate sums, and sorts the final Top 10—or offloads analytical queries to an asynchronous read replica / analytical store.

## 2. CAP Theorem Classification by Subsystem
During a network partition (`P`), different e-commerce operations require different trade-offs:
* **Stock Reservation & Payment Processing → CP (Consistency + Partition Tolerance):** If a partition isolates a node, the system **must refuse** stock decrements and payment confirmations on the isolated side rather than risk selling the same physical unit twice or double-charging a card.
* **Product Catalogue Browsing, Search & Reviews → AP (Availability + Partition Tolerance):** Served from MongoDB replica sets and PostgreSQL read replicas. Even if a node lags behind the primary by 2 seconds during a network blip, customers must still be able to browse products and read reviews uninterrupted.

## 3. Recovery Objectives (RPO / RTO) & Cloud Deployment Mapping
* **Target RPO (Recovery Point Objective):**
  * **0 seconds (`RPO = 0`)** for committed financial payments and orders using synchronous standby replication across two Availability Zones (AZs).
  * **< 5 seconds** for asynchronous read replicas serving analytics and catalogue browsing.
* **Target RTO (Recovery Time Objective):** **< 60 seconds** automated failover using managed health checks and virtual IP / DNS promotion.
* **Managed Cloud Architecture (e.g., AWS RDS for PostgreSQL + DocumentDB/Atlas + S3):**
  Replacing self-managed Docker containers with a managed cloud service hands routine operations to the provider: automated backups with point-in-time recovery, minor-version patching, monitoring, and standby promotion on failure. The mapping for NaijaCart would be:

  | Component | Lab (Docker) | Managed cloud option |
  |---|---|---|
  | Orders, stock, payments | PostgreSQL 17 primary + async replica | Amazon RDS for PostgreSQL with a Multi-AZ synchronous standby, plus read replicas for reporting |
  | Product catalogue | Single MongoDB 7 container | MongoDB Atlas three-node replica set across availability zones |
  | Product images, invoices | Not modelled | Object storage such as Amazon S3 |

* **RTO check.** AWS documents standard Multi-AZ DB instance failovers as typically taking one to two minutes, which misses the < 60 s target above. Meeting it would need the Multi-AZ DB cluster option (two readable standbys), which AWS states typically fails over in under 35 seconds, or relaxing the target. Either way the application must reconnect and retry, because a failover drops open connections.
* **Trade-offs.** Managed services cost more than self-hosting at steady load and limit control: there is no superuser access, and only the provider's supported extensions and versions are available. Moving off the platform later takes effort. Customer and payment data must also stay in a region that meets the Nigeria Data Protection Act 2023 and the company's own data-residency policy, which may limit which cloud regions can be used.
* **What I would keep from the lab.** The same failure tests I ran locally (`failover-demo-output.txt`): stop the primary, confirm writes fail until promotion, confirm committed orders survive, and confirm the application copes with gaps in order IDs.
