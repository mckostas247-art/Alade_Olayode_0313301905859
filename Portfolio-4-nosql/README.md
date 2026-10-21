# Portfolio 4: NoSQL and Advanced Data Models

## 1. Why the Product Catalogue Suits a Document Model (While Orders & Payments Do Not)
* **Polymorphic Attributes (Why MongoDB Fits the Catalogue):** In an e-commerce store, every product category has completely different attributes: a smartphone has `ramGb`, `storageGb`, and `fiveG`; a laptop has `cpu` and `screenInches`; a Senator outfit has `size` and `fabric`; formal shoes have `shoeSizeEu` and `heelHeightCm`. In a relational schema, storing these requires either dozens of sparse nullable columns or an awkward Entity-Attribute-Value (EAV) table requiring multi-way self-joins. In MongoDB, each product is stored as a self-contained JSON/BSON document with a flexible nested `attributes` sub-document, indexed cleanly via compound paths (`{ category: 1, "attributes.brand": 1 }`).
* **Why Orders, Inventory, and Payments Stay in PostgreSQL:** Financial transactions and stock reservations require strict multi-table ACID guarantees (`Portfolio 3`), foreign key referential integrity, and exact arithmetic constraints (`quantity >= 0`). Splitting an order across collections without relational constraints risks orphaned payments or oversold stock.

## 2. Embedding vs. Referencing Reviews (The 10,000-Review Boundary)
In `document-model.json`, the most recent reviews are **embedded** inside the `products` document so a product detail page loads the item, its specifications, images, and top reviews in a **single disk read** without joins.
* **What happens at 10,000 reviews:** Unbounded array growth inside a single MongoDB document causes frequent document relocations on disk and eventually risks hitting MongoDB's **16MB BSON document size limit**, while updating the document on every review creates write contention.
* **Production Pattern (Subset / Bucketing Pattern):** Embed only the **top/latest 5–10 reviews** plus pre-aggregated `reviewCount` and `ratingSum` inside the `products` document, and store the full history in a separate `reviews` collection referencing `sku` or `product_id`.

## 3. Polyglot Persistence & Consistency Trade-offs
NaijaCart uses **Polyglot Persistence**:
* **PostgreSQL (System of Record):** Authoritative source for `products.price`, `inventory.quantity`, `orders`, and `payments`.
* **MongoDB (Read-Optimised Catalogue Store):** Serves high-throughput product discovery, faceted attribute filtering, and text search.
* **Eventual Consistency Trade-off:** The boolean `inStock` field inside the MongoDB product document is updated asynchronously via change-data-capture (or domain events) whenever PostgreSQL `inventory.quantity` crosses `0`. During a brief replication window (milliseconds to seconds), MongoDB might still display `inStock: true` for an item whose last unit just sold. That is acceptable for catalogue browsing because when the customer clicks "Checkout", PostgreSQL enforces the authoritative `chk_inventory_qty_nonnegative` check before taking payment.

## How I implemented it
1. Started a MongoDB 7 container in Docker:
   ```bash
   docker run -d --name shop-mongo -p 27017:27017 mongo:7