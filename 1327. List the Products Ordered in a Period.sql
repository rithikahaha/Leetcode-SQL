# 1327. List the Products Ordered in a Period

> **Difficulty:** Easy

## Problem

We need to find the products that had **at least 100 units ordered during February 2020**.

For each qualifying product, return:

* `product_name`
* The total number of units ordered during February 2020

The `Orders` table may contain duplicate rows, so **every order row should contribute its `unit` value** to the total.

The result can be returned in any order.

### Tables

### `Products`

| Column Name        | Type    | Description         |
| ------------------ | ------- | ------------------- |
| `product_id`       | int     | Primary key         |
| `product_name`     | varchar | Name of the product |
| `product_category` | varchar | Product category    |

### `Orders`

| Column Name  | Type | Description             |
| ------------ | ---- | ----------------------- |
| `product_id` | int  | Product being ordered   |
| `order_date` | date | Date of the order       |
| `unit`       | int  | Number of units ordered |

`product_id` in `Orders` is a foreign key referencing `Products`.

---

# Solution 1: `JOIN` + `SUM()` + `GROUP BY`

```sql
SELECT
    p.product_name,
    SUM(o.unit) AS unit
FROM Products p
JOIN Orders o
    ON p.product_id = o.product_id
WHERE o.order_date >= '2020-02-01'
  AND o.order_date < '2020-03-01'
GROUP BY p.product_id, p.product_name
HAVING SUM(o.unit) >= 100;
```

### Explanation

The problem has four main steps:

1. Connect products to their orders.
2. Keep only orders from February 2020.
3. Add up the units for each product.
4. Keep products whose total is at least 100.

---

# Step 1: Join `Products` and `Orders`

```sql
FROM Products p
JOIN Orders o
    ON p.product_id = o.product_id
```

The `Products` table contains the product names, while `Orders` contains the order information.

For example:

### `Products`

| product_id | product_name          |
| ---------: | --------------------- |
|          1 | Leetcode Solutions    |
|          2 | Jewels of Stringology |

### `Orders`

| product_id | order_date | unit |
| ---------: | ---------- | ---: |
|          1 | 2020-02-05 |   60 |
|          1 | 2020-02-10 |   70 |
|          2 | 2020-02-11 |   80 |

The join connects them using:

```sql
p.product_id = o.product_id
```

giving us access to both:

```text
product_name
+
order_date
+
unit
```

We need the join because the answer asks for `product_name`, but the order quantities are stored in `Orders`.

---

# Step 2: Filter to February 2020

```sql
WHERE o.order_date >= '2020-02-01'
  AND o.order_date < '2020-03-01'
```

This means:

> Include dates starting from February 1, 2020, up to but not including March 1, 2020.

So these dates are included:

```text
2020-02-01
2020-02-05
2020-02-15
2020-02-28
2020-02-29
```

But these are excluded:

```text
2020-01-31
2020-03-01
2020-03-04
```

### Why use `< '2020-03-01'` instead of `<= '2020-02-29'`?

2020 was a leap year, so February had 29 days.

We could write:

```sql
WHERE order_date BETWEEN '2020-02-01' AND '2020-02-29'
```

and that works here.

But the pattern:

```sql
order_date >= '2020-02-01'
AND order_date < '2020-03-01'
```

is often easier to remember:

> **Start of month ≤ date < start of next month**

It also avoids having to know the last day of the month.

---

# Step 3: Group orders by product

```sql
GROUP BY p.product_id, p.product_name
```

We want to calculate the total units **for each product**.

For example, after filtering February orders, product 1 has:

| product_id | product_name       | unit |
| ---------: | ------------------ | ---: |
|          1 | Leetcode Solutions |   60 |
|          1 | Leetcode Solutions |   70 |

Grouping by product gives us one group containing those two rows.

Then we can calculate:

```text
60 + 70 = 130
```

---

# Step 4: Add the units

```sql
SUM(o.unit) AS unit
```

`SUM()` adds the `unit` values within each product group.

For product 1:

```text
60 + 70 = 130
```

For product 3:

```text
2 + 3 = 5
```

For product 5:

```text
50 + 50 = 100
```

So we get something conceptually like:

| product_name          | unit |
| --------------------- | ---: |
| Leetcode Solutions    |  130 |
| Jewels of Stringology |   80 |
| HP                    |    5 |
| Leetcode Kit          |  100 |

---

# Step 5: Keep only products with at least 100 units

```sql
HAVING SUM(o.unit) >= 100
```

This is where we apply the requirement:

> at least `100` units ordered

So:

| product_name          | unit | Keep? |
| --------------------- | ---: | ----- |
| Leetcode Solutions    |  130 | Yes   |
| Jewels of Stringology |   80 | No    |
| HP                    |    5 | No    |
| Leetcode Kit          |  100 | Yes   |

The final result is:

| product_name       | unit |
| ------------------ | ---: |
| Leetcode Solutions |  130 |
| Leetcode Kit       |  100 |

---

# Why `HAVING` instead of `WHERE`?

This is a very important SQL concept.

We use:

```sql
HAVING SUM(o.unit) >= 100
```

rather than:

```sql
WHERE SUM(o.unit) >= 100
```

because `SUM(o.unit)` is an **aggregate calculation**.

The general order is:

```text
FROM / JOIN
      ↓
WHERE
      ↓
GROUP BY
      ↓
SUM / COUNT / AVG / etc.
      ↓
HAVING
```

`WHERE` filters **individual rows before grouping**.

`HAVING` filters **groups after aggregation**.

For example:

```sql
WHERE o.order_date >= '2020-02-01'
```

filters individual order rows.

But:

```sql
HAVING SUM(o.unit) >= 100
```

filters the resulting product groups.

### Easy rule to remember

> **WHERE → filter rows**
> **HAVING → filter groups**

---

# Why `SUM()` and not `COUNT()`?

The `unit` column tells us how many products were ordered.

For example:

| order_date | unit |
| ---------- | ---: |
| 2020-02-05 |   60 |
| 2020-02-10 |   70 |

There are only **2 order rows**, but **130 units** were ordered.

So:

```sql
COUNT(*)
```

would give:

```text
2
```

while:

```sql
SUM(unit)
```

gives:

```text
130
```

The problem asks for the number of **units**, so we need `SUM()`.

---

# Why Doesn't `DISTINCT` Belong in `SUM()`?

The problem explicitly says:

> This table may have duplicate rows.

This means we **must not automatically remove duplicates**.

Consider:

| product_id | order_date | unit |
| ---------: | ---------- | ---: |
|          4 | 2020-03-04 |   60 |
|          4 | 2020-03-04 |   60 |

Those are two rows in the table.

If they were inside the requested date range, both should contribute:

```text
60 + 60 = 120
```

Therefore:

```sql
SUM(o.unit)
```

is correct.

We should **not** do:

```sql
SUM(DISTINCT o.unit)
```

because that would remove duplicate quantity values, which is not what the problem asks.

For example:

```text
60
60
```

would incorrectly become:

```text
60
```

instead of:

```text
120
```

---

# Why Use an `INNER JOIN`?

We use:

```sql
JOIN Orders o
    ON p.product_id = o.product_id
```

which is an `INNER JOIN`.

We only need products that actually have orders in February.

Products with no matching February order cannot reach 100 units anyway.

For example, product 4 only has orders in March:

| product_id | order_date | unit |
| ---------: | ---------- | ---: |
|          4 | 2020-03-01 |   20 |
|          4 | 2020-03-04 |   30 |

After the February filter, there are no rows for product 4.

Therefore, it naturally disappears.

A `LEFT JOIN` could also be used, but it would require additional handling for products with no February orders and is unnecessary for this problem.

---

# Alternative Solution: Filter in the `JOIN`

We can also put the February condition directly inside the `JOIN`:

```sql
SELECT
    p.product_name,
    SUM(o.unit) AS unit
FROM Products p
JOIN Orders o
    ON p.product_id = o.product_id
   AND o.order_date >= '2020-02-01'
   AND o.order_date < '2020-03-01'
GROUP BY p.product_id, p.product_name
HAVING SUM(o.unit) >= 100;
```

### Why does this work?

The join now only matches orders that occurred during February.

So instead of:

```text
Products
   ↓
all Orders
   ↓
filter February
```

we do:

```text
Products
   ↓
only February Orders
```

For an `INNER JOIN`, putting this filter in the `JOIN` versus the `WHERE` produces the same result here.

However, this distinction becomes very important with a `LEFT JOIN`.

---

# Important SQL Concepts

## 1. `SUM()` for totals

Use:

```sql
SUM(column)
```

when the question asks for a total.

Examples:

```sql
SUM(unit)
SUM(amount)
SUM(salary)
```

---

## 2. `GROUP BY` when calculating a total per entity

If the question asks:

> total units **for each product**

we need:

```sql
GROUP BY product_id
```

If it asks:

> total sales **for each customer**

we would use:

```sql
GROUP BY customer_id
```

The general pattern is:

```sql
SELECT
    group_column,
    SUM(value_column)
FROM table
GROUP BY group_column;
```

---

## 3. `HAVING` for aggregate conditions

If the requirement is:

> products with total units ≥ 100

we use:

```sql
HAVING SUM(unit) >= 100
```

Not:

```sql
WHERE SUM(unit) >= 100
```

because `SUM()` is calculated at the group level.

---

## 4. Foreign Key → often means a `JOIN`

`Orders.product_id` references `Products.product_id`.

That allows us to connect:

```text
Orders.product_id
        ↓
Products.product_id
```

and retrieve:

```text
Products.product_name
```

while calculating quantities from:

```text
Orders.unit
```

A foreign key doesn't automatically mean you must use a particular type of join; the required output determines whether you need `INNER JOIN`, `LEFT JOIN`, etc.

---

# Key Takeaway

This problem follows a very common SQL pattern:

```sql
SELECT
    entity,
    SUM(value) AS total
FROM table1
JOIN table2
    ON table1.id = table2.id
WHERE date_column >= 'start_date'
  AND date_column < 'next_period_start'
GROUP BY entity
HAVING SUM(value) >= threshold;
```

For this problem:

```text
JOIN
 ↓
Connect product names with orders

WHERE
 ↓
Keep only February 2020

GROUP BY
 ↓
Create one group per product

SUM(unit)
 ↓
Calculate total units per product

HAVING SUM(unit) >= 100
 ↓
Keep only products reaching 100 units
```

### The three concepts to remember from this problem

**1. Total → `SUM()`**

```sql
SUM(unit)
```

**2. Total per product → `GROUP BY`**

```sql
GROUP BY product_id, product_name
```

**3. Filter based on an aggregate → `HAVING`**

```sql
HAVING SUM(unit) >= 100
```

So the core mental pattern is:

> **Filter the relevant rows → group them → aggregate them → filter the groups.**
