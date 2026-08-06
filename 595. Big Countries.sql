# 595. Big Countries

> **Difficulty:** Easy

## Problem

A country is considered **big** if:

- Its **area** is at least **3,000,000 km²**, **or**
- Its **population** is at least **25,000,000**.

Return the **name**, **population**, and **area** of all big countries.

### Table: World

| Column | Type |
|--------|------|
| name | varchar |
| continent | varchar |
| area | int |
| population | int |
| gdp | bigint |

## SQL

```sql
SELECT name, population, area
FROM World
WHERE area >= 3000000
OR population >= 25000000;
```

## Explanation

The `WHERE` clause filters countries that satisfy **at least one** of the given conditions:

- `area >= 3000000` selects countries with an area of at least **3 million km²**.
- `population >= 25000000` selects countries with a population of at least **25 million**.

The `OR` operator ensures that countries meeting **either** condition are included in the result.

The `SELECT` statement returns only the required columns: `name`, `population`, and `area`.
