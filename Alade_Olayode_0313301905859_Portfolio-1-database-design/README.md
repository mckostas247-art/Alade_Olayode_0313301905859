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
  * **Order Status Representation:** Implemented as `TEXT` with a named `CHECK` constraint rather than `CREATE TYPE ... AS ENUM`. PostgreSQL can add a value to an `ENUM` but cannot remove one, so retiring a status would mean rebuilding the type. A `CHECK` constraint can be dropped and re-created in a migration. Adding the new constraint normally scans the table to validate existing rows; on a large `orders` table I would add it `NOT VALID` and then run `VALIDATE CONSTRAINT`, which checks the rows without blocking normal reads and writes.
  * **Regional Scaling (`customers.region`):** Adding `region` directly to `customers` prepares the schema for regional horizontal partitioning/sharding in `Portfolio 5`.

**One Design Decision I Would Change Today:**
`inventory` uses `product_id` as its sole Primary Key, which assumes a single central warehouse. As NaijaCart expands to multi-warehouse fulfilment (Lagos, Abuja, Kano), I would change `inventory`'s primary key to a composite `(warehouse_id, product_id)` referencing a new `warehouses` table.

## How I implemented it
1. Started the PostgreSQL 17 container (`postgres:17-alpine`) with `docker compose up -d db`.
2. Wrote the DDL in `schema.sql`: `NUMERIC(12,2)` for money, `TIMESTAMPTZ` for timestamps, identity primary keys, and an explicit name for every `FOREIGN KEY`, `UNIQUE` and `CHECK` constraint so that error messages identify the rule that was broken.
3. Loaded the schema and the sample rows:
   ```bash
   docker compose exec -T db psql -U shop -d shop -v ON_ERROR_STOP=1 < Alade_Olayode_0313301905859_Portfolio-1-database-design/schema.sql
   docker compose exec -T db psql -U shop -d shop -v ON_ERROR_STOP=1 < Alade_Olayode_0313301905859_Portfolio-1-database-design/sample-data.sql
   ```
4. Exported the table list and every named constraint from `pg_constraint` (`constraints.txt`, `constraints.png`).
5. Generated the ER diagram from the live schema (`information_schema` and `pg_constraint`) as Mermaid source (`er-diagram.mmd`) and rendered it to `er-diagram.png`, so the diagram matches the database exactly.

## How I tested it
I tried to break each business rule with an insert that should be refused (`constraint-tests.txt`, `screenshots/constraint-tests.png`). All six were rejected by the constraint designed for them:

| Attempt | Rule | Result |
|---|---|---|
| Product with price 0 | price must be positive | refused by `chk_products_price_positive` |
| Order line for product 999, which does not exist | lines must reference real products | refused by `fk_order_items_product` |
| Second customer with `adebayo.o@example.ng` | one account per email | refused by `uq_customers_email` |
| Set stock for product 1 to −1 | stock cannot go negative | refused by `chk_inventory_qty_nonnegative` |
| Second default address for customer 1 | one default address per customer | refused by `idx_addresses_one_default_per_customer` |
| Order with status `LOST` | only the five lifecycle states | refused by `chk_orders_status` |

The same schema was loaded on the replication primary in Portfolio 5 and used for the Portfolio 2 workload (about 2.1 million rows) without errors.
