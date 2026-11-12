# Advanced Database Systems Portfolio — MIT 8103
**Student Name:** Olayode Alade  
**Student ID:** 2026/A/MIT/0313301905859
**Institution:** Miva Open University · School of Postgraduate Studies  
**Session:** 2026/2027 Academic Session (First Semester — September 2026 Cohort)  
**Email:** o.alade5859@miva.edu.ng  
**GitHub repository:** https://github.com/mckostas247-art/AdvancedDatabase8103CA (private)

## Case Study: NaijaCart Retail Ltd (E-Commerce Platform)
* **Organisation Name:** NaijaCart Retail Ltd (a simulated Nigerian multi-category online retail platform headquartered in Lagos, serving customers nationwide).
* **Nature of the Business/System:** A transactional B2C e-commerce platform handling high-volume product browsing, order placement, real-time inventory reservations, multi-channel payment processing, and nationwide order fulfillment.
* **Users of the Database:**
  * **Customers:** Browse catalogue, manage delivery addresses, place orders, make payments, and track deliveries.
  * **Warehouse & Logistics Staff:** Manage stock quantities, pick/pack orders, and update shipment tracking statuses.
  * **Finance & Audit Team:** Reconcile payment attempts, process refunds/reversals, and audit revenue.
  * **System Administrators & Web Application Backend:** Enforce data integrity, execute automated stock checks, and serve real-time API traffic.
* **Major Data Stored:** Customers, delivery addresses, hierarchical product categories, products, real-time warehouse inventory, customer orders, order line items, payment transaction logs, delivery records, and flexible NoSQL product attributes/reviews.
* **Key Operations Supported:** Add and categorise products, place atomic multi-item orders, decrement and audit stock levels, process and reverse failed payments, track delivery progress, analyse sales performance, and scale read-heavy catalogue queries across replicas.

## Repository Structure
```text
AdvancedDatabase8103CA/
├── README.md
├── docker-compose.yml
├── Portfolio-1-database-design/
│   ├── README.md
│   ├── constraint-tests.txt
│   ├── constraints.png
│   ├── constraints.txt
│   ├── er-diagram.mmd
│   ├── er-diagram.png
│   ├── sample-data.sql
│   ├── schema.sql
│   └── screenshots/  (1 PNG, captured output)
├── Portfolio-2-query-optimization/
│   ├── README.md
│   ├── index-log.txt
│   ├── q1.sql
│   ├── q2-summary.sql
│   ├── q2.sql
│   ├── q3.sql
│   ├── queries.sql
│   ├── row-counts.txt
│   ├── seed-data.sql
│   ├── summary-view.sql
│   ├── plans/
│   │   ├── q1-after.txt
│   │   ├── q1-before.txt
│   │   ├── q2-after.txt
│   │   ├── q2-before.txt
│   │   ├── q2-covering-runs.txt
│   │   ├── q2-covering.txt
│   │   ├── q2-repeat-runs.txt
│   │   ├── q2-summary-runs.txt
│   │   ├── q2-summary.txt
│   │   ├── q3-after.txt
│   │   └── q3-before.txt
│   ├── results/
│   │   ├── q1.txt
│   │   ├── q2-summary.txt
│   │   ├── q2.txt
│   │   └── q3.txt
│   └── screenshots/  (10 PNG, captured output)
├── Portfolio-3-transaction-concurrency/
│   ├── README.md
│   ├── durability-restart.txt
│   ├── isolation-demo-output.txt
│   ├── isolation-demo.sql
│   ├── last-unit-check-constraint.txt
│   ├── last-unit-demo.md
│   ├── last-unit-for-update.txt
│   ├── last-unit-lost-update.txt
│   ├── last-unit-optimistic.txt
│   ├── place-order-demo-output.txt
│   ├── place-order-demo.sql
│   └── screenshots/  (7 PNG, captured output)
├── Portfolio-4-nosql/
│   ├── README.md
│   ├── document-model.json
│   ├── load-output.txt
│   ├── load.js
│   ├── queries-output.txt
│   ├── queries.js
│   └── screenshots/  (2 PNG, captured output)
├── Portfolio-5-distributed-cloud/
│   ├── README.md
│   ├── docker-compose.replica.yml
│   ├── failover-demo-output.txt
│   ├── replication-demo-output.txt
│   ├── replication-demo.md
│   ├── sharding-design.md
│   └── screenshots/  (2 PNG, captured output)
└── final-documentation/
    ├── Alade_Olayode_Documentation.pdf
    ├── README.md
    └── final-document.html
```

## How to run it
Requires Docker. From the repository root:
```bash
docker compose up -d db
docker compose exec -T db psql -U shop -d shop -v ON_ERROR_STOP=1 < Portfolio-1-database-design/schema.sql
docker compose exec -T db psql -U shop -d shop -v ON_ERROR_STOP=1 < Portfolio-1-database-design/sample-data.sql
```
Each portfolio folder's `README.md` gives the commands for that activity under **How I implemented it**, and the results under **How I tested it**. Portfolio 2's seed creates about 2.1 million rows and needs a few minutes and about 1 GB of free disk.

## Final documentation and AI use
The 2–3 page summary is `final-documentation/Alade_Olayode_Documentation.pdf`. Its section 5 is the AI use declaration required by the brief.
