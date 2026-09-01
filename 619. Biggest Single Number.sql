# 619. Biggest Single Number

> **Difficulty:** Easy

## Problem

A **single number** is a number that appears **exactly once** in the `MyNumbers` table.

Find the **largest single number**.

If there is no single number, return `NULL`.

### Table: `MyNumbers`

| Column | Type |
|--------|------|
| num | int |

The table may contain duplicate values.

---

## Solution 1: Using `GROUP BY`, `HAVING`, and `MAX()`

```sql
SELECT MAX(num) AS num
FROM MyNumbers
GROUP BY num
HAVING COUNT(num) = 1
ORDER BY num DESC
LIMIT 1;
```

### Explanation

The problem has two steps:

1. Find the numbers that appear exactly once.
2. Find the largest one among them.

---

### Step 1: Group identical numbers together

```sql
GROUP BY num
```

This puts all occurrences of the same number into the same group.

For Example 1:

| num |
|-----|
| 8 |
| 8 |
| 3 |
| 3 |
| 1 |
| 4 |
| 5 |
| 6 |

After grouping, we conceptually have:

```text
8 → 2 occurrences
3 → 2 occurrences
1 → 1 occurrence
4 → 1 occurrence
5 → 1 occurrence
6 → 1 occurrence
```

---

### Step 2: Keep only single numbers

```sql
HAVING COUNT(num) = 1
```

`COUNT(num)` counts how many times each number appears.

The condition:

```sql
COUNT(num) = 1
```

keeps only numbers that appear exactly once.

Therefore:

```text
1
4
5
6
```

are the single numbers.

> **Important:** We use `HAVING` because `COUNT()` is an aggregate function. `WHERE` cannot be used to filter the result of an aggregate.

---

### Step 3: Find the largest single number

```sql
MAX(num)
```

`MAX()` returns the largest value from the remaining single numbers.

For the example:

```text
MAX(1, 4, 5, 6) = 6
```

---

### ⚠️ Important issue with this approach

There is a subtle problem with writing:

```sql
SELECT MAX(num)
FROM MyNumbers
GROUP BY num
HAVING COUNT(num) = 1;
```

Because `GROUP BY num` creates **one output row per single number**, `MAX(num)` does not find the maximum across all single numbers.

It produces:

```text
1
4
5
6
```

instead of just:

```text
6
```

So to use this approach correctly, we need another level of aggregation.

### Correct version:

```sql
SELECT MAX(num) AS num
FROM (
    SELECT num
    FROM MyNumbers
    GROUP BY num
    HAVING COUNT(num) = 1
) AS single_numbers;
```

This is the recommended `GROUP BY` solution.

---

## Solution 1 (Correct): Using a Subquery

```sql
SELECT MAX(num) AS num
FROM (
    SELECT num
    FROM MyNumbers
    GROUP BY num
    HAVING COUNT(num) = 1
) AS single_numbers;
```

### Explanation

The inner query:

```sql
SELECT num
FROM MyNumbers
GROUP BY num
HAVING COUNT(num) = 1
```

finds all single numbers.

For Example 1:

```text
1
4
5
6
```

The outer query:

```sql
SELECT MAX(num)
```

then finds the largest value:

```text
6
```

---

### What happens if there are no single numbers?

Suppose the table contains:

```text
8
8
7
7
3
3
3
```

The inner query returns **zero rows** because no number appears exactly once.

Then:

```sql
MAX(num)
```

over an empty result returns:

```text
NULL
```

which is exactly what the problem asks for.

> **Key idea:** Aggregate functions such as `MAX()` return `NULL` when there are no values to aggregate.

---

## Solution 2: Using a Correlated Subquery

```sql
SELECT MAX(num) AS num
FROM MyNumbers n
WHERE (
    SELECT COUNT(*)
    FROM MyNumbers
    WHERE num = n.num
) = 1;
```

### Explanation

Instead of grouping all numbers first, this solution checks each number individually.

For every row `n`, the subquery asks:

> "How many times does this number appear in `MyNumbers`?"

For example, for `8`:

```sql
SELECT COUNT(*)
FROM MyNumbers
WHERE num = 8;
```

returns:

```text
2
```

So `8` is not a single number.

For `6`:

```sql
SELECT COUNT(*)
FROM MyNumbers
WHERE num = 6;
```

returns:

```text
1
```

So `6` is a single number.

The condition:

```sql
WHERE (...) = 1
```

keeps only numbers that appear exactly once.

Then:

```sql
MAX(num)
```

finds the largest one.

If no number appears once, `MAX()` returns `NULL`.

---

## Solution 3: Using `GROUP BY` with `ORDER BY` and `LIMIT`

Another way to solve the problem is to first find the single numbers and then sort them from largest to smallest.

```sql
SELECT num
FROM MyNumbers
GROUP BY num
HAVING COUNT(num) = 1
ORDER BY num DESC
LIMIT 1;
```

### Explanation

The first part:

```sql
GROUP BY num
HAVING COUNT(num) = 1
```

finds the single numbers.

For Example 1:

```text
1
4
5
6
```

Then:

```sql
ORDER BY num DESC
```

sorts them:

```text
6
5
4
1
```

Finally:

```sql
LIMIT 1
```

keeps only the largest value:

```text
6
```

### But what about `NULL` when there are no single numbers?

If there are no single numbers, this query returns **zero rows**, rather than a row containing `NULL`.

Therefore, this version does **not exactly satisfy** the problem's requirement by itself.

The safer solution is the subquery + `MAX()` approach:

```sql
SELECT MAX(num) AS num
FROM (
    SELECT num
    FROM MyNumbers
    GROUP BY num
    HAVING COUNT(num) = 1
) AS single_numbers;
```

That guarantees one output row and gives `NULL` when no single number exists.

---

## `COUNT(num)` vs `COUNT(*)`

You may also see:

```sql
HAVING COUNT(*) = 1
```

instead of:

```sql
HAVING COUNT(num) = 1
```

Both work for this problem.

### `COUNT(*)`

```sql
COUNT(*)
```

counts every row in the group.

### `COUNT(num)`

```sql
COUNT(num)
```

counts non-`NULL` values of `num`.

Since the problem contains integers and we are interested in occurrences of each number, either works here.

The important part is:

```sql
HAVING COUNT(...) = 1
```

because we want numbers that occur exactly once.

---

## Key Takeaway

This problem follows the pattern:

```text
Find values that occur exactly once
            ↓
GROUP BY value
            ↓
HAVING COUNT(*) = 1
            ↓
Find the largest value
            ↓
MAX()
```

The cleanest solution is:

```sql
SELECT MAX(num) AS num
FROM (
    SELECT num
    FROM MyNumbers
    GROUP BY num
    HAVING COUNT(num) = 1
) AS single_numbers;
```

### Pattern to remember

Whenever you see:

> **"Find the largest/smallest value that appears exactly once."**

Think:

```sql
SELECT MAX(column)
FROM (
    SELECT column
    FROM table
    GROUP BY column
    HAVING COUNT(*) = 1
) AS single_values;
```

This pattern is especially useful because `MAX()` naturally returns `NULL` when there are no qualifying values.
