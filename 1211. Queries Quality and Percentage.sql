# 1211. Queries Quality and Percentage

> **Difficulty:** Easy

## Problem

For each `query_name`, calculate:

1. **Quality** = Average of `(rating / position)`
2. **Poor Query Percentage** = Percentage of queries where `rating < 3`

Round both values to **2 decimal places**.

Return the result table in **any order**.

### Table: Queries

| Column | Type |
|--------|------|
| query_name | varchar |
| result | varchar |
| position | int |
| rating | int |

---

## Solution 1: Using `AVG()`

```sql
SELECT query_name,
       ROUND(AVG(rating / position), 2) AS quality,
       ROUND(AVG(rating < 3) * 100, 2) AS poor_query_percentage
FROM Queries
GROUP BY query_name;
```

### Explanation

This solution uses the `AVG()` function to calculate both the query quality and the poor query percentage.

#### Step 1: Group by query

```sql
GROUP BY query_name
```

This groups all rows belonging to the same query together.

For example:

**Dog**

| rating | position |
|--------|---------:|
| 5 | 1 |
| 5 | 2 |
| 1 | 200 |

**Cat**

| rating | position |
|--------|---------:|
| 2 | 5 |
| 3 | 3 |
| 4 | 7 |

Each group is processed independently.

---

#### Step 2: Calculate the quality

```sql
AVG(rating / position)
```

For every row, SQL computes:

```
rating / position
```

For **Dog**:

| Rating | Position | Rating / Position |
|-------:|---------:|------------------:|
| 5 | 1 | 5.000 |
| 5 | 2 | 2.500 |
| 1 | 200 | 0.005 |

Then `AVG()` calculates:

```
(5 + 2.5 + 0.005) / 3
= 2.5017
≈ 2.50
```

---

#### Step 3: Calculate the poor query percentage

```sql
AVG(rating < 3)
```

In MySQL,

- `TRUE` is treated as **1**
- `FALSE` is treated as **0**

The expression:

```sql
rating < 3
```

returns:

| Rating | rating < 3 |
|-------:|-----------:|
| 5 | 0 |
| 5 | 0 |
| 1 | 1 |

Then,

```sql
AVG(rating < 3)
```

becomes

```
(0 + 0 + 1) / 3
= 0.3333
```

Multiplying by 100 gives:

```
33.33%
```

---

#### Step 4: Round the results

```sql
ROUND(..., 2)
```

rounds both values to **2 decimal places**.

> **Note:** This is the cleanest solution because `AVG()` automatically computes both the average ratio and the percentage of poor queries without requiring separate `COUNT()` or `SUM()` calculations.

---

## Solution 2: Using `SUM()` and `COUNT()`

```sql
SELECT query_name,
       ROUND(SUM(rating / position) / COUNT(*), 2) AS quality,
       ROUND(SUM(rating < 3) * 100.0 / COUNT(*), 2) AS poor_query_percentage
FROM Queries
GROUP BY query_name;
```

### Explanation

This solution calculates both values using their mathematical formulas.

#### Step 1: Calculate the quality

```sql
SUM(rating / position) / COUNT(*)
```

For **Dog**:

```
(5 + 2.5 + 0.005) / 3
= 2.5017
≈ 2.50
```

This is equivalent to using `AVG(rating / position)`.

---

#### Step 2: Count poor queries

```sql
SUM(rating < 3)
```

Since MySQL treats boolean expressions as numeric values:

- `TRUE = 1`
- `FALSE = 0`

`SUM(rating < 3)` counts the number of poor queries.

Example:

| Rating | rating < 3 |
|-------:|-----------:|
| 5 | 0 |
| 5 | 0 |
| 1 | 1 |

```
SUM = 1
```

---

#### Step 3: Calculate the percentage

```sql
SUM(rating < 3) * 100.0 / COUNT(*)
```

For **Dog**:

```
1 × 100 / 3
= 33.33%
```

Using `100.0` ensures floating-point division instead of integer division.

---

#### Step 4: Round the results

```sql
ROUND(..., 2)
```

rounds both values to two decimal places.

> **Note:** This solution is more explicit because it directly follows the mathematical formulas. However, the `AVG()` solution is shorter and generally preferred.

---

## Solution 3: Using `CASE`

```sql
SELECT query_name,
       ROUND(AVG(rating / position), 2) AS quality,
       ROUND(
           AVG(
               CASE
                   WHEN rating < 3 THEN 1
                   ELSE 0
               END
           ) * 100,
           2
       ) AS poor_query_percentage
FROM Queries
GROUP BY query_name;
```

### Explanation

Instead of relying on MySQL treating boolean expressions as `1` and `0`, this solution uses a `CASE` expression.

```sql
CASE
    WHEN rating < 3 THEN 1
    ELSE 0
END
```

converts each row into:

| Rating | Value |
|-------:|------:|
| 5 | 0 |
| 5 | 0 |
| 1 | 1 |

`AVG()` then calculates:

```
Number of poor queries
-----------------------
Total number of queries
```

Multiplying by `100` converts the ratio into a percentage.

The quality calculation remains the same as in Solution 1.

> **Note:** `CASE` is ANSI SQL standard and works across virtually all SQL databases, making this solution more portable than relying on MySQL's boolean evaluation.
