# 1757. Recyclable and Low Fat Products

> **Difficulty:** Easy

## Problem

Find the IDs of products that are both **low fat** and **recyclable**.

**Table: Products**

| Column | Type |
|--------|------|
| product_id | int |
| low_fats | enum ('Y', 'N') |
| recyclable | enum ('Y', 'N') |

## SQL

```sql
SELECT product_id
FROM Products
WHERE low_fats = 'Y'
AND recyclable = 'Y';
```

## Explanation

Use the `WHERE` clause to filter rows where both `low_fats` and `recyclable` are `'Y'`.
