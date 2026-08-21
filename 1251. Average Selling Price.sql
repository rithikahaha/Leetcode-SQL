# 1251. Average Selling Price

> **Difficulty:** Easy

## Problem

Find the **average selling price** for each product.

The average selling price is calculated as:

```
Total Revenue
--------------------------
Total Units Sold
```

where:

```
Total Revenue = Σ (price × units)
```

If a product has **no units sold**, its average price is **0**.

Return the result table in **any order**.

### Table: Prices

| Column | Type |
|--------|------|
| product_id | int |
| start_date | date |
| end_date | date |
| price | int |

### Table: UnitsSold

| Column | Type |
|--------|------|
| product_id | int |
| purchase_date | date |
| units | int |

---

## Solution 1: Using `LEFT JOIN`

```sql
SELECT p.product_id,
       ROUND(
           IFNULL(SUM(p.price * u.units) / SUM(u.units), 0),
           2
       ) AS average_price
FROM Prices p
LEFT JOIN UnitsSold u
ON p.product_id = u.product_id
AND u.purchase_date BETWEEN p.start_date AND p.end_date
GROUP BY p.product_id;
```

### Explanation

This solution joins each sale with the correct product price based on the purchase date.

#### Step 1: Match each sale with its price

```sql
LEFT JOIN UnitsSold u
ON p.product_id = u.product_id
AND u.purchase_date BETWEEN p.start_date AND p.end_date
```

The join matches:

- the same `product_id`
- a `purchase_date` that falls within the corresponding price period.

For example:

| product_id | purchase_date | price period | price |
|------------|---------------|--------------|------:|
| 1 | 2019-02-25 | 2019-02-17 → 2019-02-28 | 5 |
| 1 | 2019-03-01 | 2019-03-01 → 2019-03-22 | 20 |

Since the price periods never overlap for a product, each sale matches exactly one price.

#### Step 2: Calculate total revenue

```sql
SUM(p.price * u.units)
```

Each sale contributes:

```
price × units
```

For Product 1:

| Price | Units | Revenue |
|------:|------:|--------:|
| 5 | 100 | 500 |
| 20 | 15 | 300 |

Total revenue:

```
500 + 300 = 800
```

#### Step 3: Calculate total units sold

```sql
SUM(u.units)
```

For Product 1:

```
100 + 15 = 115
```

#### Step 4: Calculate the average selling price

```sql
SUM(price × units)
------------------
SUM(units)
```

For Product 1:

```
800 / 115 = 6.9565...
```

#### Step 5: Handle products with no sales

If a product has no matching sales:

```text
SUM(price × units) → NULL
SUM(units)         → NULL
```

Therefore,

```sql
IFNULL(..., 0)
```

returns `0` as required by the problem.

#### Step 6: Round the result

```sql
ROUND(..., 2)
```

rounds the average selling price to **2 decimal places**.

> **Note:** A `LEFT JOIN` is required because every product should appear in the output, even if it has no matching sales. In that case, the average selling price is reported as `0`.

---

## Solution 2: Using `COALESCE()`

```sql
SELECT p.product_id,
       ROUND(
           COALESCE(SUM(p.price * u.units) / SUM(u.units), 0),
           2
       ) AS average_price
FROM Prices p
LEFT JOIN UnitsSold u
ON p.product_id = u.product_id
AND u.purchase_date BETWEEN p.start_date AND p.end_date
GROUP BY p.product_id;
```

### Explanation

This solution is identical to Solution 1, except that it uses `COALESCE()` instead of `IFNULL()`.

```sql
COALESCE(expression, 0)
```

returns:

- the calculated average if it exists.
- `0` if the expression evaluates to `NULL`.

> **Note:** `COALESCE()` is part of the SQL standard and is supported by most relational database systems, whereas `IFNULL()` is specific to MySQL.
