# Portfolio 4: NoSQL and Advanced Data Models

## 1. Why the Product Catalogue Suits a Document Model (While Orders & Payments Do Not)
* **Polymorphic Attributes (Why MongoDB Fits the Catalogue):** In an e-commerce store, every product category has completely different attributes: in my catalogue a phone has `ramGb`, `storageGb` and `network`; a laptop has `cpu`, `ssdGb` and `screenInches`; a Senator outfit has `size` and `fabric`; shoes have `shoeSizeEu` and `material`; headphones have `wireless`, `anc` and `batteryHours`. In a relational schema, storing these requires either dozens of sparse nullable columns or an awkward Entity-Attribute-Value (EAV) table requiring multi-way self-joins. In MongoDB, each product is stored as a self-contained JSON/BSON document with a flexible nested `attributes` sub-document, indexed cleanly via compound paths (`{ category: 1, "attributes.brand": 1 }`).
* **Why Orders, Inventory, and Payments Stay in PostgreSQL:** Financial transactions and stock reservations require strict multi-table ACID guarantees (`Portfolio 3`), foreign key referential integrity, and exact arithmetic constraints (`quantity >= 0`). Splitting an order across collections without relational constraints risks orphaned payments or oversold stock.

## 2. Embedding vs. Referencing Reviews (The 10,000-Review Boundary)
In `document-model.json`, the most recent reviews are **embedded** inside the `products` document so a product detail page loads the item, its specifications, images, and top reviews in a **single disk read** without joins.
* **What happens at 10,000 reviews:** at roughly 150 bytes per review, the array alone would be about 1.5 MB. That is still under MongoDB's 16 MB document limit, but every product page would read all 1.5 MB to show a handful of reviews, and every new review would make the storage engine rewrite the whole document. Popular products would become the slowest pages, and the array has no upper bound, so the 16 MB limit would eventually be reached.
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
   ```
2. Designed one product document (`document-model.json`): core fields (`sku`, `name`, `category`, `price`, `inStock`), a flexible `attributes` sub-document that differs by category, `images`, and an embedded `reviews` array.
3. Wrote `load.js`, which drops and reloads the `products` collection with 21 products in three categories (phones 8, computing 7, fashion 6), then creates two indexes: a compound index `{ category: 1, "attributes.brand": 1 }` and a text index on `name`.
4. Wrote `queries.js` with four checks: a filter on a nested attribute, a text search, an aggregation of ratings per category, and an `explain()` to confirm the compound index is used.
5. Ran both scripts and saved the output:
   ```bash
   docker exec -i shop-mongo mongosh shop --quiet < Alade_Olayode_0313301905859_Portfolio-4-nosql/load.js > Alade_Olayode_0313301905859_Portfolio-4-nosql/load-output.txt
   docker exec -i shop-mongo mongosh shop --quiet < Alade_Olayode_0313301905859_Portfolio-4-nosql/queries.js > Alade_Olayode_0313301905859_Portfolio-4-nosql/queries-output.txt
   ```

## How I tested it
Results are in `load-output.txt` and `queries-output.txt`; images in `screenshots/`.

| Check | Result |
|---|---|
| Load | `Inserted documents count: 21`; indexes `category_1_attributes.brand_1` and `name_text` created |
| Phones with `attributes.ramGb >= 8` | 6 phones returned (PHN-001, 002, 003, 004, 005, 007) |
| Text search for "wireless" | 4 products returned (AUD-001, AUD-002, LAP-005, PHN-003) |
| Average rating per category | computing 4.71 (7 reviews), phones 4.44 (9 reviews), fashion 4.17 (6 reviews). I checked phones by hand: 9 ratings totalling 40 gives 4.44. |
| Index use for `{ category: "phones", "attributes.brand": "Samsung" }` | winning plan `FETCH` over `IXSCAN` on `category_1_attributes.brand_1`, so no collection scan |

**A bug I found and fixed:** the first run of the aggregation failed with `MongoServerError: The $round accumulator is a unary operator`, because I had put `$round` inside `$group`. `$group` only accepts accumulators such as `$avg`, so I now calculate the average in `$group` and round it in a separate `$set` stage.
