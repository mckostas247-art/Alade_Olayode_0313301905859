# Portfolio 1: Database Design and Modelling

## 1. Case Study Statement
**NaijaCart Retail Ltd** is an online B2C retail platform operating in Nigeria. The relational database serves five user groups: **customers** (placing and tracking orders), **warehouse staff** (managing inventory and dispatches), **finance officers** (reconciling payments and reversals), **system administrators**, and the **web application backend**. It stores nine core entities: `customers`, `addresses`, `categories`, `products`, `inventory`, `orders`, `order_items`, `payments`, and `deliveries`. Key operations include product catalogue management, atomic order placement, real-time stock decrements, payment logging, and shipment tracking.

## 2. Schema Architecture, Keys, and Constraints

| Table | Purpose | Primary Key | Foreign Keys | Business Rules Enforced via Constraints |
|---|---|---|---|---|
| `customers` | Registered buyers and regional routing metadata | `customer_id` (Identity) | None | `uq_customers_email`: Prevents duplicate accounts per email. |
| `addresses` | Customer shipping destinations | `address_id` (Identity) | `customer_id` → `customers` | Partial unique index `idx_addresses_one_default_per_customer`: Ensures at most one default address per buyer. |
| `categories` | Hierarchical product taxonomy | `category_id` (Identity) | `parent_id` → `categories` | `uq_categories_name`: Unique category names; self-reference supports subcategories. |
| `products` | Sellable catalogue items | `product_id` (Identity) | `category_id` → `categories` | `uq_products_sku`: Unique stock-keeping unit; `chk_products_price_positive`: Enforces `price > 0` using exact `NUMERIC(12,2)`. |
| `inventory` | Current warehouse stock per item | `product_id` | `product_id` → `products` | `chk_inventory_qty_nonnegative`: Enforces `quantity >= 0`, preventing negative stock / overselling at the storage engine layer. |
| `orders` | Order header and lifecycle state | `order_id` (Identity) | `customer_id` → `customers` | `chk_orders_status`: Restricts states to valid lifecycle transitions; `chk_orders_total_nonnegative`: `total >= 0`. |
| `order_items` | Line items within an order | `(order_id, product_id)` | `order_id` → `orders`, `product_id` → `products` | Composite PK prevents duplicate product lines on the same order; `quantity > 0` and `unit_price > 0`. |
| `payments` | Payment attempts per order | `payment_id` (Identity) | `order_id` → `orders` | Supports multiple attempts (e.g., `FAILED` then `SUCCESS`); enforces `amount > 0` and valid payment methods. |
| `deliveries` | Fulfilment and courier tracking | `delivery_id` (Identity) | `order_id` → `orders`, `address_id` → `addresses` | `uq_deliveries_order` & `uq_deliveries_tracking`: One shipment per order with a unique tracking code. |

## 3. Normalisation (3NF) and Deliberate Design Choices
All tables satisfy **Third Normal Form (3NF)**:
* **First Normal Form (1NF):** Every column holds atomic values; repeating groups (order lines, payment attempts, addresses) are extracted into separate child tables.
* **Second Normal Form (2NF):** In `order_items`, the composite primary key is `(order_id, product_id)`. The functional dependencies are:
  * `(order_id, product_id) -> quantity, unit_price`
  Neither `quantity` nor `unit_price` depends solely on `order_id` or solely on `product_id` (at the time of purchase). Current product names and SKUs live in `products` (`product_id -> name, sku, category_id`), eliminating partial dependencies.
* **Third Normal Form (3NF):** There are no transitive dependencies among non-key attributes:
  * **Why `order_items.unit_price` does not violate 3NF:** `products.price` represents the *current* catalogue price, whereas `order_items.unit_price` captures the *historical contractual price* at the exact timestamp the order was placed. If `products.price` increases next month, historical invoices must never change.
  * **Stored `orders.total`:** `orders.total` is stored as a controlled denormalisation so order history queries (`Portfolio 2, Query 1`) do not have to re-aggregate `order_items` across millions of rows on every page load. It is kept consistent inside the atomic order-placement transaction (`Portfolio 3`).
  * **Order Status Representation:** Implemented as `TEXT` with a named `CHECK` constraint rather than `CREATE TYPE ... AS ENUM` because modifying PostgreSQL `ENUM` values in production migrations (`DROP`/`REMOVE`) is restrictive, whereas altering a `CHECK` constraint only requires a brief metadata check.
  * **Regional Scaling (`customers.region`):** Adding `region` directly to `customers` prepares the schema for regional horizontal partitioning/sharding in `Portfolio 5`.

**One Design Decision I Would Change Today:**
`inventory` uses `product_id` as its sole Primary Key, which assumes a single central warehouse. As NaijaCart expands to multi-warehouse fulfilment (Lagos, Abuja, Kano), I would change `inventory`'s primary key to a composite `(warehouse_id, product_id)` referencing a new `warehouses` table.

## How I implemented it
1. Started the PostgreSQL 17 container via `docker compose up -d db`.
2. Wrote the DDL script in `portfolio-1-database-design/schema.sql` using `NUMERIC(12,2)` for monetary columns, `TIMESTAMPTZ` for timestamps, and explicit names for every `FOREIGN KEY`, `UNIQUE`, and `CHECK` constraint.
3. Applied the schema and seed rows using:
   ```bash
   docker compose exec -T db psql -U shop -d shop -v ON_ERROR_STOP=1 -f - < portfolio-1-database-design/schema.sql
   docker compose exec -T db psql -U shop -d shop -v ON_ERROR_STOP=1 -f - < portfolio-1-database-design/sample-data.sql