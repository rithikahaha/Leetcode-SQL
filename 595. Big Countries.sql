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

## Solution 2: Using `UNION`

```sql
SELECT name, population, area
FROM World
WHERE area >= 3000000

UNION

SELECT name, population, area
FROM World
WHERE population >= 25000000;
```

### Explanation

The query is divided into two separate `SELECT` statements:

- The first query returns countries with an **area of at least 3,000,000 km²**.
- The second query returns countries with a **population of at least 25,000,000**.

The `UNION` operator combines the results of both queries and automatically removes duplicate rows. This ensures that a country satisfying **both** conditions appears only once in the final result.

Using `UNION` is an alternative to the `OR` operator and can sometimes make the query easier to understand by separating each condition into its own query.
