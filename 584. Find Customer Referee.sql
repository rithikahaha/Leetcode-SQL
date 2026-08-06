# 584. Find Customer Referee

> **Difficulty:** Easy

## Problem

Find the names of customers who are either:

- **Not referred** by any customer.
- **Referred by** a customer whose `id` is **not equal to 2**.

### Table: Customer

| Column | Type |
|--------|------|
| id | int |
| name | varchar |
| referee_id | int |

## Solution 1: Using `OR` and `IS NULL`

```sql
SELECT name
FROM Customer
WHERE referee_id != 2
OR referee_id IS NULL;
```

### Explanation

The `WHERE` clause filters customers who:

- Have a `referee_id` other than `2`.
- Have no referee (`NULL`).

The `OR referee_id IS NULL` condition is required because comparisons involving `NULL` (such as `NULL != 2`) evaluate to `UNKNOWN`, not `TRUE`. Therefore, rows with `NULL` values must be handled explicitly.

---

## Solution 2: Using `IFNULL()`

```sql
SELECT name
FROM Customer
WHERE IFNULL(referee_id, 0) != 2;
```

### Explanation

The `IFNULL()` function replaces `NULL` values with `0`.

- If `referee_id` is `NULL`, it becomes `0`, and since `0 != 2`, the customer is included.
- If `referee_id` is any value other than `2`, the customer is included.
- If `referee_id` is `2`, the condition evaluates to `FALSE`, so the customer is excluded.

Using `IFNULL()` provides a concise way to handle `NULL` values without writing a separate `OR referee_id IS NULL` condition.
