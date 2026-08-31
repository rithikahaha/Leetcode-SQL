# 1193. Monthly Transactions I

> **Difficulty:** Medium

## Problem

For each **month and country**, calculate:

- The total number of transactions.
- The number of approved transactions.
- The total amount of all transactions.
- The total amount of approved transactions.

Return the result table in **any order**.

### Table: Transactions

| Column | Type |
|--------|------|
| id | int |
| country | varchar |
| state | enum ('approved', 'declined') |
| amount | int |
| trans_date | date |

---

## Solution 1: Using Conditional Aggregation

```sql
SELECT DATE_FORMAT(trans_date, '%Y-%m') AS month,
       country,
       COUNT(*) AS trans_count,
       SUM(state = 'approved') AS approved_count,
       SUM(amount) AS trans_total_amount,
       SUM(IF(state = 'approved', amount, 0)) AS approved_total_amount
FROM Transactions
GROUP BY DATE_FORMAT(trans_date, '%Y-%m'),
         country;
```

### Explanation

This solution uses **conditional aggregation** to calculate the total and approved transaction statistics in a single query.

#### Step 1: Extract the month

```sql
DATE_FORMAT(trans_date, '%Y-%m') AS month
```

The `trans_date` column contains the complete date, but the problem asks for results **by month**.

For example:

```text
2018-12-18 → 2018-12
2018-12-19 → 2018-12
2019-01-01 → 2019-01
2019-01-07 → 2019-01
```

`DATE_FORMAT()` converts the date into the required `YYYY-MM` format.

---

#### Step 2: Group by month and country

```sql
GROUP BY DATE_FORMAT(trans_date, '%Y-%m'),
         country
```

We need a separate result for every **month-country combination**.

For example:

| month | country |
|-------|---------|
| 2018-12 | US |
| 2019-01 | US |
| 2019-01 | DE |

Transactions belonging to the same month and country are grouped together.

---

#### Step 3: Count all transactions

```sql
COUNT(*) AS trans_count
```

`COUNT(*)` counts every transaction in each month-country group, regardless of its state.

For December 2018 in the US:

```text
2 transactions
```

---

#### Step 4: Count approved transactions

```sql
SUM(state = 'approved') AS approved_count
```

In MySQL, a boolean expression evaluates to:

- `TRUE` → `1`
- `FALSE` → `0`

So:

```sql
state = 'approved'
```

produces:

| state | value |
|-------|------:|
| approved | 1 |
| declined | 0 |

Therefore, `SUM()` adds the `1`s and effectively counts the approved transactions.

For example:

```text
1 + 0 = 1 approved transaction
```

> **Alternative:** You could also write this using `COUNT()`:
>
> ```sql
> COUNT(CASE WHEN state = 'approved' THEN 1 END)
> ```
>
> This is more portable because it does not rely on MySQL's boolean-to-integer behavior.

---

#### Step 5: Calculate the total transaction amount

```sql
SUM(amount) AS trans_total_amount
```

This adds the amounts of **all transactions** in each month-country group.

For December 2018 in the US:

```text
1000 + 2000 = 3000
```

---

#### Step 6: Calculate the approved transaction amount

```sql
SUM(IF(state = 'approved', amount, 0))
```

`IF()` checks whether each transaction was approved.

- If approved → use its `amount`.
- If declined → use `0`.

For example:

| state | amount | value |
|-------|-------:|------:|
| approved | 1000 | 1000 |
| declined | 2000 | 0 |

Then:

```text
1000 + 0 = 1000
```

So the result is the **total amount of approved transactions only**.

> **Alternative:** `CASE` can be used instead of `IF()`:
>
> ```sql
> SUM(
>     CASE
>         WHEN state = 'approved' THEN amount
>         ELSE 0
>     END
> )
> ```
>
> `CASE` is part of the SQL standard, while `IF()` is MySQL-specific.

---

## Solution 2: Using `CASE`

```sql
SELECT DATE_FORMAT(trans_date, '%Y-%m') AS month,
       country,
       COUNT(*) AS trans_count,
       SUM(
           CASE
               WHEN state = 'approved' THEN 1
               ELSE 0
           END
       ) AS approved_count,
       SUM(amount) AS trans_total_amount,
       SUM(
           CASE
               WHEN state = 'approved' THEN amount
               ELSE 0
           END
       ) AS approved_total_amount
FROM Transactions
GROUP BY DATE_FORMAT(trans_date, '%Y-%m'),
         country;
```

### Explanation

This solution uses `CASE` expressions for the conditional calculations.

#### Approved transaction count

```sql
SUM(
    CASE
        WHEN state = 'approved' THEN 1
        ELSE 0
    END
)
```

Each transaction becomes either:

```text
approved → 1
declined → 0
```

`SUM()` then counts the approved transactions.

#### Approved transaction amount

```sql
SUM(
    CASE
        WHEN state = 'approved' THEN amount
        ELSE 0
    END
)
```

For approved transactions, the actual amount is included.

For declined transactions, `0` is included.

This gives the total amount of approved transactions.

> **Note:** This solution is more verbose than Solution 1 but is more **portable across SQL databases** because `CASE` is standard SQL.

---

## Solution 3: Using `COUNT()` with `CASE`

```sql
SELECT DATE_FORMAT(trans_date, '%Y-%m') AS month,
       country,
       COUNT(*) AS trans_count,
       COUNT(
           CASE
               WHEN state = 'approved' THEN 1
           END
       ) AS approved_count,
       SUM(amount) AS trans_total_amount,
       SUM(
           CASE
               WHEN state = 'approved' THEN amount
               ELSE 0
           END
       ) AS approved_total_amount
FROM Transactions
GROUP BY DATE_FORMAT(trans_date, '%Y-%m'),
         country;
```

### Explanation

This solution uses `COUNT()` to count approved transactions.

```sql
COUNT(
    CASE
        WHEN state = 'approved' THEN 1
    END
)
```

The `CASE` expression returns:

- `1` for approved transactions.
- `NULL` for declined transactions.

Since `COUNT(column)` ignores `NULL` values, only approved transactions are counted.

For example:

| state | CASE result |
|-------|-------------|
| approved | 1 |
| declined | NULL |
| approved | 1 |

Therefore:

```text
COUNT(1, NULL, 1) = 2
```

The other calculations work the same way as in the previous solutions.

> **Note:** `COUNT(CASE WHEN ...)` is a useful pattern to remember for conditional counting. Unlike `COUNT(*)`, it counts only rows where the expression produces a non-`NULL` value.
