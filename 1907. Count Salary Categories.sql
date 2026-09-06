# 1907. Count Salary Categories

> **Difficulty:** Medium

## Problem

You are given an `Accounts` table containing the monthly income of bank accounts.

### Table: `Accounts`

| Column       | Type |
| ------------ | ---- |
| `account_id` | int  |
| `income`     | int  |

* `account_id` is the primary key.
* Each row represents one bank account and its monthly income.

We need to count the number of accounts in each of these three salary categories:

| Category           | Income                       |
| ------------------ | ---------------------------- |
| **Low Salary**     | `< 20000`                    |
| **Average Salary** | `20000` to `50000` inclusive |
| **High Salary**    | `> 50000`                    |

The result **must contain all three categories**, even when no accounts belong to a category.

If a category has no accounts, its count should be `0`.

---

## Solution: `UNION ALL` + Conditional `COUNT`

```sql
SELECT 'Low Salary' AS category,
       COUNT(CASE WHEN income < 20000 THEN 1 END) AS accounts_count
FROM Accounts

UNION ALL

SELECT 'Average Salary' AS category,
       COUNT(CASE WHEN income BETWEEN 20000 AND 50000 THEN 1 END) AS accounts_count
FROM Accounts

UNION ALL

SELECT 'High Salary' AS category,
       COUNT(CASE WHEN income > 50000 THEN 1 END) AS accounts_count
FROM Accounts;
```

### Explanation

The tricky part of this problem is that the result must **always contain all three categories**.

For example, if there are no accounts with income between `$20,000` and `$50,000`, we still need:

```text
Average Salary | 0
```

A normal `GROUP BY` solution can have a problem here because a category with no matching rows may simply **not appear**.

So instead, we explicitly create one query for each category and combine the three results using `UNION ALL`.

---

# Step 1: Count Low Salary Accounts

```sql
SELECT 'Low Salary' AS category,
       COUNT(CASE WHEN income < 20000 THEN 1 END) AS accounts_count
FROM Accounts
```

The condition for Low Salary is:

```sql
income < 20000
```

The word **strictly** is important.

An income of exactly `$20,000` is **not** Low Salary.

---

## How does `COUNT(CASE WHEN ...)` work?

The expression:

```sql
CASE
    WHEN income < 20000 THEN 1
END
```

returns:

```text
1
```

when the condition is true.

If the condition is false, there is no `ELSE`, so `CASE` returns:

```text
NULL
```

For example:

| income | CASE result |
| -----: | ----------: |
|  12747 |           1 |
|  25000 |        NULL |
|  87709 |        NULL |
| 108939 |        NULL |

Then:

```sql
COUNT(...)
```

counts only the **non-NULL** values.

So:

```text
1
NULL
NULL
NULL
```

produces:

```text
1
```

Therefore:

```text
Low Salary → 1
```

---

# Step 2: Count Average Salary Accounts

```sql
SELECT 'Average Salary' AS category,
       COUNT(
           CASE
               WHEN income BETWEEN 20000 AND 50000
               THEN 1
           END
       ) AS accounts_count
FROM Accounts
```

The problem says Average Salary includes the **inclusive** range:

```text
[20000, 50000]
```

So both endpoints are included:

```text
20000 ≤ income ≤ 50000
```

That's why we can use:

```sql
income BETWEEN 20000 AND 50000
```

---

## What does `BETWEEN` mean?

In SQL:

```sql
income BETWEEN 20000 AND 50000
```

is equivalent to:

```sql
income >= 20000
AND income <= 50000
```

`BETWEEN` is **inclusive**.

So:

| Income | Average Salary? |
| -----: | --------------- |
| 19,999 | No              |
| 20,000 | Yes             |
| 35,000 | Yes             |
| 50,000 | Yes             |
| 50,001 | No              |

---

# Step 3: Count High Salary Accounts

```sql
SELECT 'High Salary' AS category,
       COUNT(CASE WHEN income > 50000 THEN 1 END) AS accounts_count
FROM Accounts
```

The condition is:

```sql
income > 50000
```

The word **strictly greater** means that `$50,000` is not considered High Salary.

For example:

|  Income | High Salary? |
| ------: | ------------ |
|  50,000 | No           |
|  50,001 | Yes          |
|  87,709 | Yes          |
| 108,939 | Yes          |

---

# Step 4: Combine the Three Queries

We use:

```sql
UNION ALL
```

between the three queries:

```sql
SELECT ...
FROM Accounts

UNION ALL

SELECT ...
FROM Accounts

UNION ALL

SELECT ...
FROM Accounts;
```

Each individual query produces exactly **one row**.

Therefore, the final result always contains:

```text
Low Salary
Average Salary
High Salary
```

even if one of the counts is `0`.

---

## Why `UNION ALL` instead of `UNION`?

`UNION` removes duplicate rows.

`UNION ALL` keeps all rows.

Here, we specifically want all three category rows:

```text
Low Salary
Average Salary
High Salary
```

Since the category names are different, they won't be duplicates anyway.

Still, `UNION ALL` is the more appropriate choice because we are simply combining three independent results and don't need duplicate removal.

---

# Why Not Use `GROUP BY`?

A natural first thought might be:

```sql
SELECT ...
FROM Accounts
GROUP BY ...
```

But there is an important issue.

Suppose the table contains:

| account_id | income |
| ---------: | -----: |
|          1 | 10,000 |
|          2 | 60,000 |

There are no Average Salary accounts.

If we classify each account and then `GROUP BY category`, SQL would only have rows for:

```text
Low Salary
High Salary
```

It would not automatically create:

```text
Average Salary | 0
```

But the problem specifically requires **all three categories**.

Using three separate queries guarantees that every category is produced.

---

# Why Not Use `WHERE`?

For example:

```sql
SELECT COUNT(*)
FROM Accounts
WHERE income < 20000;
```

This correctly counts Low Salary accounts.

But by itself, it doesn't give us the other categories.

We could write three separate queries with `WHERE`, but then we'd still need to combine them.

Using:

```sql
COUNT(CASE WHEN ...)
```

lets each query scan the table and count only the rows belonging to its category.

---

# Understanding `COUNT(CASE WHEN ...)`

This is a very useful SQL pattern.

The general structure is:

```sql
COUNT(
    CASE
        WHEN condition THEN 1
    END
)
```

Think of it as:

```text
For every row:
    If condition is TRUE
        → produce 1
    Otherwise
        → produce NULL

COUNT()
    → counts the 1s
    → ignores the NULLs
```

For example:

```sql
COUNT(CASE WHEN income > 50000 THEN 1 END)
```

means:

> Count the rows where income is greater than 50,000.

---

# Why Doesn't `COUNT()` Count the `NULL`s?

This is an important SQL rule.

```sql
COUNT(column)
```

counts only **non-NULL values**.

For example:

```text
1
1
NULL
1
NULL
```

produces:

```text
3
```

because only three values are non-NULL.

That's exactly why this works:

```sql
COUNT(CASE WHEN condition THEN 1 END)
```

The `CASE` creates `1` only for matching rows and `NULL` for everything else.

---

# Why Does an Empty Category Return `0`?

Suppose there are no Average Salary accounts.

Then:

```sql
CASE
    WHEN income BETWEEN 20000 AND 50000
    THEN 1
END
```

returns `NULL` for every row.

So conceptually:

```text
NULL
NULL
NULL
NULL
```

Then:

```sql
COUNT(...)
```

returns:

```text
0
```

The query still produces a row because the `FROM Accounts` query itself still returns one aggregate result.

Therefore we get:

```text
Average Salary | 0
```

This is exactly what the problem requires.

---

# Example Walkthrough

Given:

| account_id | income |
| ---------: | -----: |
|          3 | 108939 |
|          2 |  12747 |
|          8 |  87709 |
|          6 |  91796 |

## Low Salary

Condition:

```sql
income < 20000
```

Only:

```text
12747
```

qualifies.

Therefore:

```text
Low Salary → 1
```

---

## Average Salary

Condition:

```sql
income BETWEEN 20000 AND 50000
```

None of the accounts qualify.

Therefore:

```text
Average Salary → 0
```

---

## High Salary

Condition:

```sql
income > 50000
```

These qualify:

```text
108939
87709
91796
```

Therefore:

```text
High Salary → 3
```

Final result:

| category       | accounts_count |
| -------------- | -------------: |
| Low Salary     |              1 |
| Average Salary |              0 |
| High Salary    |              3 |

---

# Alternative Solution: `SUM()` with Boolean Conditions

Another common way to do conditional counting in MySQL is:

```sql
SELECT 'Low Salary' AS category,
       SUM(income < 20000) AS accounts_count
FROM Accounts

UNION ALL

SELECT 'Average Salary' AS category,
       SUM(income BETWEEN 20000 AND 50000) AS accounts_count
FROM Accounts

UNION ALL

SELECT 'High Salary' AS category,
       SUM(income > 50000) AS accounts_count
FROM Accounts;
```

### Why does this work?

In MySQL, a Boolean expression evaluates to:

```text
TRUE  → 1
FALSE → 0
```

So:

```sql
income < 20000
```

can effectively produce:

```text
1
0
0
1
```

and:

```sql
SUM(...)
```

adds those values together.

For example:

```text
1 + 0 + 0 + 0 = 1
```

Therefore, it counts how many rows satisfy the condition.

This is a very concise MySQL technique for **conditional counting**.

---

## `COUNT(CASE WHEN ...)` vs `SUM(condition)`

Both can solve the problem.

### `COUNT(CASE WHEN ...)`

```sql
COUNT(CASE WHEN income < 20000 THEN 1 END)
```

Think:

> Produce `1` for matching rows and `NULL` for everything else, then count the non-NULL values.

### `SUM(condition)`

```sql
SUM(income < 20000)
```

Think:

> Convert TRUE/FALSE into `1/0` and add them.

The `COUNT(CASE WHEN ...)` version is often easier to understand because it makes the conditional counting logic explicit.

---

# Key Takeaway

The main solution is:

```sql
SELECT 'Low Salary' AS category,
       COUNT(CASE WHEN income < 20000 THEN 1 END) AS accounts_count
FROM Accounts

UNION ALL

SELECT 'Average Salary' AS category,
       COUNT(CASE WHEN income BETWEEN 20000 AND 50000 THEN 1 END) AS accounts_count
FROM Accounts

UNION ALL

SELECT 'High Salary' AS category,
       COUNT(CASE WHEN income > 50000 THEN 1 END) AS accounts_count
FROM Accounts;
```

The most important concepts are:

* `UNION ALL` → combines the three category results.
* `CASE WHEN` → checks whether an account belongs to a category.
* `COUNT()` → counts the non-NULL results produced by `CASE`.
* `BETWEEN` → checks an **inclusive** range.
* `<` → strictly less than.
* `>` → strictly greater than.
* `COUNT(CASE WHEN ...)` → useful pattern for conditional counting.
* Creating each category separately ensures that **categories with zero accounts still appear**.

### General pattern to remember

When a problem says:

> "Return every category, including categories with zero records."

A useful approach is:

```sql
SELECT 'Category A' AS category,
       COUNT(CASE WHEN condition_a THEN 1 END) AS count
FROM table

UNION ALL

SELECT 'Category B' AS category,
       COUNT(CASE WHEN condition_b THEN 1 END) AS count
FROM table;
```

The key idea is:

```text
CASE WHEN condition
       ↓
    matching row → 1
    non-matching → NULL
       ↓
COUNT()
       ↓
number of matching rows
```

And because each category has its own query, **even an empty category gets a `0` row**.
