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

## SQL

```sql
SELECT name
FROM Customer
WHERE referee_id != 2
OR referee_id IS NULL;
```

## Explanation

Use the `WHERE` clause to filter customers who:

- Have a `referee_id` other than `2`.
- Have no referee (`NULL`).

The `OR referee_id IS NULL` condition is necessary because `NULL` values are not returned by the condition `referee_id != 2`.
