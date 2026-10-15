# Advanced Database Systems Portfolio — MIT 8103
**Student Name:** Olayode Alade  
**Student ID:** 2026/A/MIT/0313301905859
**Institution:** Miva Open University · School of Postgraduate Studies  
**Session:** 2026/2027 Academic Session (First Semester — September 2026 Cohort)

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
├── docker-compose.yml
├── README.md
├── Portfolio-1-database-design/
│   ├── schema.sql
│   ├── sample-data.sql
│   ├── er-diagram.png
│   ├── constraints.png
│   └── README.md
├── Portfolio-2-query-optimisation/
│   ├── seed-data.sql
│   ├── queries.sql
│   ├── results/
│   ├── plans/
│   └── README.md
├── Portfolio-3-transactions-concurrency/
│   ├── place-order-demo.sql
│   ├── last-unit-demo.md
│   ├── isolation-demo.sql
│   └── README.md
├── Portfolio-4-nosql/
│   ├── document-model.json
│   ├── load.js
│   ├── queries.js
│   └── README.md
├── Portfolio-5-distributed-cloud/
│   ├── docker-compose.replica.yml
│   ├── replication-demo.md
│   ├── sharding-design.md
│   └── README.md
└── final-documentation/
    ├── Alade_Olayode_0313301905859_MIT8103.pdf
    └── README.md