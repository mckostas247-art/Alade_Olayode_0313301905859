# Distributed Architecture & Sharding Design for NaijaCart Retail Ltd

## 1. Horizontal Sharding Strategy
As NaijaCart scales beyond a single primary node's write throughput (e.g., 50M+ orders across Nigeria), tables are classified into **Sharded Tables** and **Reference (Global) Tables**:

* **Shard Key Selection (`customer_id` Hash Sharding):**
  * **Sharded Tables:** `customers`, `addresses`, `orders`, `order_items`, `payments`, and `deliveries` are co-located on shards partitioned by `HASH(customer_id) % N` (or via Citus distributed tables on `customer_id`, adding `customer_id` to child tables).
  * **Why `customer_id` Hash Beats Geographic/Region Sharding:** Over 55% of Nigerian e-commerce volume originates in Lagos. Range/list sharding by `region` creates a severe **hot shard** on the Lagos node while northern/eastern shards sit under-utilised. Hashing `customer_id` distributes write load evenly across all shards and ensures that a customer's entire order history (`Portfolio 2, Query 1`) executes locally on a **single shard** without cross-node joins.
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
  Replacing self-managed Docker containers with a managed cloud deployment offloads