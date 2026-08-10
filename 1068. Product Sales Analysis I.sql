# 1068. Product Sales Analysis I

> **Difficulty:** Easy

## Problem

Report the **product name**, **year**, and **price** for each sale in the `Sales` table.

Return the result table in **any order**.

### Table: Sales

| Column | Type |
|--------|------|
| sale_id | int |
| product_id | int |
| year | int |
| quantity | int |
| price | int |

### Table: Product

| Column | Type |
|--------|------|
| product_id | int |
| product_name | varchar |

## Solution 1: Using `INNER JOIN`

```sql
SELECT p.product_name, s.year, s.price
FROM Sales s
INNER JOIN Product p
ON s.product_id = p.product_id;
```

### Explanation

An `INNER JOIN` returns only the rows where a matching `product_id` exists in both tables.

- `Sales` contains the sale details such as `year` and `price`.
- `Product` contains the corresponding `product_name`.
- The join condition `s.product_id = p.product_id` matches each sale with its product.
- The `SELECT` statement returns the required columns: `product_name`, `year`, and `price`.

Since `product_id` in the `Sales` table is a **foreign key** referencing `Product.product_id`, every sale is guaranteed to have a matching product. Therefore, `INNER JOIN` is the most appropriate and commonly used solution.

---

## Solution 2: Using `JOIN`

```sql
SELECT p.product_name, s.year, s.price
FROM Sales s
JOIN Product p
ON s.product_id = p.product_id;
```

### Explanation

`JOIN` is simply the shorthand form of `INNER JOIN`.

- It returns only the rows where `product_id` matches in both tables.
- The result is identical to using `INNER JOIN`.
- Many SQL developers prefer `JOIN` because it is shorter and more concise, while others explicitly write `INNER JOIN` for readability.

Both queries produce the same output.

---

## Solution 3: Using `LEFT JOIN`

```sql
SELECT p.product_name, s.year, s.price
FROM Sales s
LEFT JOIN Product p
ON s.product_id = p.product_id;
```

### Explanation

A `LEFT JOIN` returns **all rows** from the left table (`Sales`) and the matching rows from the right table (`Product`).

- `Sales` is used as the left table because the problem asks for information about **every sale**.
- The join condition `s.product_id = p.product_id` matches each sale with its corresponding product.
- If a matching product did not exist, the `product_name` would be returned as `NULL`.

However, in this problem, `product_id` in the `Sales` table is a **foreign key** referencing `Product.product_id`. This guarantees that every `product_id` in `Sales` already exists in the `Product` table.

As a result, every sale has a matching product, so `LEFT JOIN` produces the **same result** as `INNER JOIN`.

> **Note:** A foreign key does **not** automatically mean you should use `INNER JOIN`. The choice of join depends on the problem requirements:
>
> - Use **`INNER JOIN`** when you only need matching records from both tables.
> - Use **`LEFT JOIN`** when you need **all rows from the left table**, even if there is no matching row in the right table.
>
> In this problem, both joins return the same result because the foreign key guarantees that every sale has a matching product.
