# 1581. Customer Who Visited but Did Not Make Any Transactions

> **Difficulty:** Easy

## Problem

Find the IDs of customers who **visited the mall but did not make any transactions**, along with the number of such visits.

Return the result table in **any order**.

### Table: Visits

| Column | Type |
|--------|------|
| visit_id | int |
| customer_id | int |

### Table: Transactions

| Column | Type |
|--------|------|
| transaction_id | int |
| visit_id | int |
| amount | int |

## Solution 1: Using `LEFT JOIN`

```sql
SELECT v.customer_id,
       COUNT(*) AS count_no_trans
FROM Visits v
LEFT JOIN Transactions t
ON v.visit_id = t.visit_id
WHERE t.transaction_id IS NULL
GROUP BY v.customer_id;
```

### Explanation

A `LEFT JOIN` returns **all rows** from the left table (`Visits`) and the matching rows from the right table (`Transactions`).

- `Visits` is used as the left table because we want to consider **every visit**.
- The join condition `v.visit_id = t.visit_id` matches each visit with its corresponding transaction(s).
- If a visit has **no matching transaction**, all columns from the `Transactions` table become `NULL`.
- The condition `WHERE t.transaction_id IS NULL` filters only those visits where no transaction was made.
- `GROUP BY customer_id` groups the remaining visits by customer.
- `COUNT(*)` counts the number of visits without transactions for each customer.

> **Note:** `COUNT(v.visit_id)` would also produce the same result because `visit_id` is a unique identifier and is never `NULL`. However, `COUNT(*)` is generally preferred since it explicitly counts **rows**, making the query more readable and independent of any specific column.

---

## Solution 2: Using `NOT IN`

```sql
SELECT customer_id,
       COUNT(*) AS count_no_trans
FROM Visits
WHERE visit_id NOT IN (
    SELECT visit_id
    FROM Transactions
)
GROUP BY customer_id;
```

### Explanation

The subquery retrieves all `visit_id`s that have at least one transaction.

- `NOT IN` filters out those visits, leaving only visits with **no transactions**.
- The remaining visits are grouped by `customer_id`.
- `COUNT(*)` calculates the number of visits without transactions for each customer.

> **Note:** `NOT IN` works correctly here because `Transactions.visit_id` contains no `NULL` values. If the subquery could return `NULL`, the comparison would evaluate to `UNKNOWN`, and no rows would be returned. In such cases, `NOT EXISTS` is the safer choice.

---

## Solution 3: Using `NOT EXISTS`

```sql
SELECT v.customer_id,
       COUNT(*) AS count_no_trans
FROM Visits v
WHERE NOT EXISTS (
    SELECT 1
    FROM Transactions t
    WHERE v.visit_id = t.visit_id
)
GROUP BY v.customer_id;
```

### Explanation

The `NOT EXISTS` clause checks whether a matching transaction exists for each visit.

- For every row in the `Visits` table, the subquery searches for a transaction with the same `visit_id`.
- If no matching transaction exists, `NOT EXISTS` evaluates to `TRUE`, so that visit is included.
- The remaining visits are grouped by `customer_id`.
- `COUNT(*)` returns the number of visits without transactions for each customer.

> **Note:** `SELECT 1` is commonly used because the subquery only checks for the existence of a matching row. The actual value selected is irrelevant, so `SELECT 1` is considered a SQL best practice.

---

## Solution 4: Using `RIGHT JOIN`

```sql
SELECT v.customer_id,
       COUNT(*) AS count_no_trans
FROM Transactions t
RIGHT JOIN Visits v
ON t.visit_id = v.visit_id
WHERE t.transaction_id IS NULL
GROUP BY v.customer_id;
```

### Explanation

A `RIGHT JOIN` returns **all rows** from the right table (`Visits`) and the matching rows from the left table (`Transactions`).

- `Visits` is placed on the right so that every visit appears in the result.
- The join condition matches each visit with its corresponding transaction(s).
- If no matching transaction exists, the columns from `Transactions` are returned as `NULL`.
- The `WHERE t.transaction_id IS NULL` condition filters visits without transactions.
- Finally, the visits are grouped by `customer_id`, and `COUNT(*)` calculates how many such visits each customer made.

This produces the same result as the `LEFT JOIN` solution, with the tables reversed.
