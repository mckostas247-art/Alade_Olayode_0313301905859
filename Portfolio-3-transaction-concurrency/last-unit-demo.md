# Concurrency Control Demo: Buying the Last Unit in Stock

## Setup
```sql
UPDATE inventory SET quantity = 1, version = 0 WHERE product_id = 1;