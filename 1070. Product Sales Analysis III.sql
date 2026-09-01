# 1070. Product Sales Analysis III

> **Difficulty:** Medium

## Problem

For each `product_id`, find the **first year** in which the product was sold.

Then return **all sales entries** for that product that occurred in its first year.

The result should contain:

- `product_id`
- `first_year`
- `quantity`
- `price`

Return the result table in **any order**.

### Table: Sales

| Column | Type |
|--------|------|
| sale_id | int |
| product_id | int |
| year | int |
| quantity | int |
| price | int |

---

## Solution 1: Using `MIN()` and `JOIN`

```sql
SELECT s.product_id,
       f.first_year,
       s.quantity,
       s.price
FROM Sales s
JOIN (
    SELECT product_id,
           MIN(year) AS first_year
    FROM Sales
    GROUP BY product_id
) f
ON s.product_id = f.product_id
AND s.year = f.first_year;
```

### Explanation

The main challenge is that we need to:

1. Find the **earliest year** for every product.
2. Return **all sales from that year**.

We cannot simply use `GROUP BY product_id` in the final query because we need the individual `quantity` and `price` values from every sale in the first year.

---

### Step 1: Find the first year for each product

```sql
SELECT product_id,
       MIN(year) AS first_year
FROM Sales
GROUP BY product_id
```

`MIN(year)` finds the earliest year in which each product was sold.

For the example:

| product_id | first_year |
|------------|-----------:|
| 100 | 2008 |
| 200 | 2011 |

This gives us the first year for every product.

---

### Step 2: Join the result back to `Sales`

```sql
FROM Sales s
JOIN (...) f
ON s.product_id = f.product_id
AND s.year = f.first_year
```

We join the original `Sales` table with the first-year table using **two conditions**:

```sql
s.product_id = f.product_id
```

This ensures we're looking at the same product.

And:

```sql
s.year = f.first_year
```

This ensures that the sale occurred during that product's first year.

---

### Why do we need both conditions?

Suppose Product 100 has:

| product_id | year | quantity |
|------------|-----:|---------:|
| 100 | 2008 | 10 |
| 100 | 2008 | 20 |
| 100 | 2009 | 15 |

Its first year is:

```text
2008
```

If we joined only on:

```sql
s.product_id = f.product_id
```

we would get **all sales for Product 100**, including the 2009 sale.

By also joining on:

```sql
s.year = f.first_year
```

we keep only the sales from 2008.

---

### Step 3: Why does this return multiple sales from the first year?

This is important.

The problem states:

> A product may have multiple sales entries in the same year.

Suppose Product 100 has:

| sale_id | product_id | year | quantity | price |
|--------:|------------|-----:|---------:|------:|
| 1 | 100 | 2008 | 10 | 5000 |
| 2 | 100 | 2008 | 20 | 4500 |
| 3 | 100 | 2009 | 12 | 5000 |

The subquery gives:

| product_id | first_year |
|------------|-----------:|
| 100 | 2008 |

The join matches **both** 2008 rows.

Therefore, both sales are returned.

> **Key point:** We are finding the **first year**, not the **first sale**. So we must return every sale that happened during that year.

---

## Solution 2: Using `MIN()` with a Correlated Subquery

```sql
SELECT product_id,
       year AS first_year,
       quantity,
       price
FROM Sales s
WHERE year = (
    SELECT MIN(year)
    FROM Sales
    WHERE product_id = s.product_id
);
```

### Explanation

This solution does not require a separate derived table.

For each row in `Sales`, the subquery finds the earliest year for that row's product:

```sql
SELECT MIN(year)
FROM Sales
WHERE product_id = s.product_id
```

For example, for Product 100:

```text
MIN(year) = 2008
```

The outer query then checks:

```sql
WHERE year = 2008
```

So every sale belonging to Product 100 in 2008 is returned.

---

### Why does the subquery use `s.product_id`?

```sql
WHERE product_id = s.product_id
```

The `s` refers to the current row from the outer query.

This makes the subquery **correlated** with the outer query.

In other words:

> "For this particular product, find its earliest year."

Then the outer query keeps the row if its year equals that earliest year.

---

## Solution 3: Using `RANK()`

```sql
SELECT product_id,
       year AS first_year,
       quantity,
       price
FROM (
    SELECT product_id,
           year,
           quantity,
           price,
           RANK() OVER (
               PARTITION BY product_id
               ORDER BY year
           ) AS rnk
    FROM Sales
) s
WHERE rnk = 1;
```

### Explanation

This solution uses the `RANK()` window function to identify the first year for each product.

---

### Step 1: Partition by product

```sql
PARTITION BY product_id
```

This creates a separate window for each product.

For example:

```text
Product 100 → its sales
Product 200 → its sales
Product 300 → its sales
```

---

### Step 2: Order each product's sales by year

```sql
ORDER BY year
```

The earliest year comes first.

For Product 100:

| year | rank |
|-----:|-----:|
| 2008 | 1 |
| 2008 | 1 |
| 2009 | 3 |

Because `RANK()` gives the **same rank to tied values**, all sales from the first year receive:

```text
rnk = 1
```

---

### Step 3: Keep rank 1

```sql
WHERE rnk = 1
```

This returns all sales that occurred in the earliest year for each product.

> **Important:** This is why `RANK()` works particularly well here. We want **all rows tied for the earliest year**.

---

## `RANK()` vs `ROW_NUMBER()` — Important

You might be tempted to write:

```sql
ROW_NUMBER() OVER (
    PARTITION BY product_id
    ORDER BY year
)
```

But that would be different.

Suppose Product 100 has:

| sale_id | year |
|--------:|-----:|
| 1 | 2008 |
| 2 | 2008 |
| 3 | 2009 |

`ROW_NUMBER()` could produce:

| sale_id | year | row_number |
|--------:|-----:|-----------:|
| 1 | 2008 | 1 |
| 2 | 2008 | 2 |
| 3 | 2009 | 3 |

Filtering:

```sql
WHERE row_number = 1
```

would return only **one** of the 2008 sales.

But the problem asks for **all sales in the first year**.

`RANK()` produces:

| sale_id | year | rank |
|--------:|-----:|-----:|
| 1 | 2008 | 1 |
| 2 | 2008 | 1 |
| 3 | 2009 | 3 |

So:

```sql
WHERE rank = 1
```

correctly returns **both** 2008 sales.

> **Rule to remember:** If a problem asks for **all rows tied for the minimum/maximum value**, `RANK()` is often a good window-function choice. If it asks for exactly **one row**, `ROW_NUMBER()` is usually more appropriate.

---

## Key Takeaways

This problem follows the pattern:

```text
Find the minimum value per group
            ↓
Match/filter rows having that minimum value
```

### Using aggregation:

```sql
MIN(year)
GROUP BY product_id
```

Then join it back to the original table.

### Using a correlated subquery:

```sql
WHERE year = (
    SELECT MIN(year)
    ...
)
```

### Using a window function:

```sql
RANK() OVER (
    PARTITION BY product_id
    ORDER BY year
)
```

Then:

```sql
WHERE rnk = 1
```

### Most important distinction

This problem asks for the **first year**, not the **first sale**.

Therefore, if a product has multiple sales in its first year, **all of them must be returned**.

That is why `RANK()` works here, while `ROW_NUMBER()` would incorrectly discard the other sales from that same first year.
