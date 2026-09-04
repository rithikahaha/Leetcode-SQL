# 180. Consecutive Numbers

> **Difficulty:** Medium

## Problem

You are given a `Logs` table containing a sequence of numbers.

### Table: `Logs`

| Column | Type    |
| ------ | ------- |
| `id`   | int     |
| `num`  | varchar |

* `id` is the primary key.
* `id` is an auto-increment column starting from `1`.
* The `id` determines the order in which the numbers appear.

Find all numbers that appear **at least three times consecutively**.

Return the result in any order.

---

## Solution 1: Self Join

```sql id="h4j8sq"
SELECT DISTINCT l1.num AS ConsecutiveNums
FROM Logs l1
JOIN Logs l2
    ON l2.id = l1.id + 1
JOIN Logs l3
    ON l3.id = l1.id + 2
WHERE l1.num = l2.num
  AND l2.num = l3.num;
```

### Explanation

The key idea is:

> To find a number appearing three times consecutively, compare three consecutive rows and check whether their `num` values are the same.

For example:

| id | num |
| -: | --: |
|  1 |   1 |
|  2 |   1 |
|  3 |   1 |

The three rows have:

```text
id 1 → 1
id 2 → 1
id 3 → 1
```

Since all three values are the same, `1` is a consecutive number.

---

## Step 1: Join the table to itself

We use the `Logs` table three times:

```sql id="6ldg82"
FROM Logs l1
JOIN Logs l2
JOIN Logs l3
```

Each alias represents a different position in the sequence:

```text
l1 → first row
l2 → second row
l3 → third row
```

We need three rows because the problem asks for a number appearing **at least three times consecutively**.

---

## Step 2: Find the next row

The `id` column is sequential because the problem tells us it is an auto-increment column starting from `1`.

Therefore, if:

```text
l1.id = 1
```

then the next row is:

```text
l2.id = 2
```

So we write:

```sql id="e0l8h8"
ON l2.id = l1.id + 1
```

This means:

> Match `l2` with the row immediately after `l1`.

For example:

```text
l1.id = 4
l2.id = 5
```

---

## Step 3: Find the row two positions later

We also need a third consecutive row.

So:

```sql id="4q6vqn"
ON l3.id = l1.id + 2
```

means:

> Match `l3` with the row two positions after `l1`.

For example:

```text
l1.id = 1
l2.id = 2
l3.id = 3
```

Now we have three consecutive rows.

---

## Step 4: Make sure all three numbers are equal

Finding three consecutive rows isn't enough.

We need the **same number** to appear in all three rows.

So we use:

```sql id="y9n0gq"
WHERE l1.num = l2.num
  AND l2.num = l3.num
```

This checks:

```text
first number = second number
AND
second number = third number
```

If both are true, then all three numbers are the same.

For example:

```text
1 = 1 → TRUE
1 = 1 → TRUE
```

Therefore, `1` appears three times consecutively.

---

## Why do we use `AND`?

We need both comparisons to be true.

```sql id="4p2ozx"
l1.num = l2.num
AND
l2.num = l3.num
```

If we used `OR`, a situation like this could incorrectly qualify:

```text
1
1
2
```

because:

```text
1 = 1 → TRUE
1 = 2 → FALSE
```

With `OR`, the overall condition would still be true.

But these are **not** three consecutive occurrences of the same number.

Therefore, we need `AND`.

---

## Step 5: Why `DISTINCT`?

We use:

```sql id="5i6z4j"
SELECT DISTINCT l1.num AS ConsecutiveNums
```

because the same number can appear in multiple groups of three.

For example:

| id | num |
| -: | --: |
|  1 |   1 |
|  2 |   1 |
|  3 |   1 |
|  4 |   1 |

There are two possible groups of three:

```text
Rows 1, 2, 3 → 1, 1, 1
Rows 2, 3, 4 → 1, 1, 1
```

Both satisfy the condition.

Without `DISTINCT`, we could get:

```text
1
1
```

But the result should contain the number only once.

Therefore:

```sql id="c2i5x6"
SELECT DISTINCT
```

removes duplicate results.

---

# Understanding "At Least Three Times"

The problem says:

> appear **at least three times consecutively**

This means four or five consecutive occurrences should also qualify.

For example:

```text id="ry43z0"
1
1
1
1
```

Our self join can detect:

```text
Rows 1,2,3 → 1,1,1
Rows 2,3,4 → 1,1,1
```

So `1` is returned.

We don't need to explicitly check for four or five rows.

If a number appears four, five, or more times consecutively, there will always be at least one group of three consecutive rows containing that number.

---

# Example Walkthrough

Given:

| id | num |
| -: | --: |
|  1 |   1 |
|  2 |   1 |
|  3 |   1 |
|  4 |   2 |
|  5 |   1 |
|  6 |   2 |
|  7 |   2 |

### Starting at `id = 1`

The three rows are:

```text
id 1 → 1
id 2 → 1
id 3 → 1
```

All three numbers are equal.

Therefore:

```text
1 → qualifies
```

---

### Starting at `id = 2`

The three rows are:

```text
id 2 → 1
id 3 → 1
id 4 → 2
```

The values are not all equal.

Therefore:

```text
1 → does not qualify from this group
```

But `1` has already qualified from rows 1–3.

---

### Starting at `id = 3`

The three rows are:

```text
id 3 → 1
id 4 → 2
id 5 → 1
```

Not all equal.

No match.

---

### Starting at `id = 4`

The three rows are:

```text
id 4 → 2
id 5 → 1
id 6 → 2
```

Not all equal.

No match.

---

### Starting at `id = 5`

The three rows are:

```text
id 5 → 1
id 6 → 2
id 7 → 2
```

Not all equal.

No match.

Therefore, the final answer is:

| ConsecutiveNums |
| --------------- |
| 1               |

---

# Solution 2: `LAG()`

We can also solve this problem using a **window function**.

```sql id="y7t6be"
SELECT DISTINCT num AS ConsecutiveNums
FROM (
    SELECT num,
           LAG(num, 1) OVER (ORDER BY id) AS prev_num,
           LAG(num, 2) OVER (ORDER BY id) AS prev_prev_num
    FROM Logs
) l
WHERE num = prev_num
  AND num = prev_prev_num;
```

### Explanation

`LAG()` allows us to look at values from previous rows without joining the table to itself.

The basic syntax is:

```sql id="3atxj5"
LAG(column, number_of_rows) OVER (ORDER BY ...)
```

For example:

```sql id="v9m85p"
LAG(num, 1) OVER (ORDER BY id)
```

means:

> Give me the `num` value from **1 row before** the current row.

And:

```sql id="m9c9d5"
LAG(num, 2) OVER (ORDER BY id)
```

means:

> Give me the `num` value from **2 rows before** the current row.

---

## Step 1: Look one row back

```sql id="5t8j84"
LAG(num, 1) OVER (ORDER BY id) AS prev_num
```

Suppose we have:

| id | num |
| -: | --: |
|  1 |   1 |
|  2 |   1 |
|  3 |   1 |
|  4 |   2 |

After applying `LAG(num, 1)`:

| id | num | prev_num |
| -: | --: | -------: |
|  1 |   1 |     NULL |
|  2 |   1 |        1 |
|  3 |   1 |        1 |
|  4 |   2 |        1 |

For row `3`, `prev_num` is the value from row `2`.

---

## Step 2: Look two rows back

```sql id="3z8a6d"
LAG(num, 2) OVER (ORDER BY id) AS prev_prev_num
```

Now:

| id | num | prev_num | prev_prev_num |
| -: | --: | -------: | ------------: |
|  1 |   1 |     NULL |          NULL |
|  2 |   1 |        1 |          NULL |
|  3 |   1 |        1 |             1 |
|  4 |   2 |        1 |             1 |

For row `3`, we have:

```text
current       = 1
one row back  = 1
two rows back = 1
```

Therefore, three consecutive `1`s have been found.

---

## Step 3: Compare the three values

The outer query checks:

```sql id="m8dh0p"
WHERE num = prev_num
  AND num = prev_prev_num
```

This means:

```text
current value = previous value
AND
current value = value two rows before
```

Therefore:

```text
current = previous = previous previous
```

which means the same number appeared three times consecutively.

---

## Why `ORDER BY id`?

This is extremely important.

`LAG()` needs to know what "previous row" means.

We use:

```sql id="2t7aaz"
OVER (ORDER BY id)
```

because `id` defines the sequence of the log records.

So:

```text
ORDER BY id
```

establishes:

```text
id 1
 ↓
id 2
 ↓
id 3
 ↓
id 4
```

Without `ORDER BY id`, SQL would not have the required ordering for determining which row is previous.

---

# Self Join vs `LAG()`

Both approaches solve the same problem.

### Self Join

```sql id="n5i8sy"
JOIN Logs l2
    ON l2.id = l1.id + 1
JOIN Logs l3
    ON l3.id = l1.id + 2
```

Think:

> Join the current row with the next two rows.

### `LAG()`

```sql id="3qyqpp"
LAG(num, 1) OVER (ORDER BY id)
LAG(num, 2) OVER (ORDER BY id)
```

Think:

> Look backward at the previous two rows.

Both approaches are useful to know.

---

## How to Recognize This Type of Problem

Whenever a SQL problem contains words like:

* **consecutive**
* **previous**
* **next**
* **immediately before**
* **immediately after**
* **three rows in a row**
* **consecutive days**

you should think about either:

```text
Self Join
```

or:

```text
LAG() / LEAD()
```

For example:

```text
Current
Previous
Two rows before
```

can be represented with:

```sql id="8g3dqs"
LAG(column, 1) OVER (ORDER BY ...)
LAG(column, 2) OVER (ORDER BY ...)
```

---

## Key Takeaway

The simplest way to think about this problem is:

```text
Current value
    =
Previous value
    =
Value two rows before
```

Using `LAG()`:

```sql id="gy9f9e"
SELECT DISTINCT num AS ConsecutiveNums
FROM (
    SELECT num,
           LAG(num, 1) OVER (ORDER BY id) AS prev_num,
           LAG(num, 2) OVER (ORDER BY id) AS prev_prev_num
    FROM Logs
) l
WHERE num = prev_num
  AND num = prev_prev_num;
```

Or using a self join:

```sql id="3m9d8b"
SELECT DISTINCT l1.num AS ConsecutiveNums
FROM Logs l1
JOIN Logs l2
    ON l2.id = l1.id + 1
JOIN Logs l3
    ON l3.id = l1.id + 2
WHERE l1.num = l2.num
  AND l2.num = l3.num;
```

### General pattern to remember

For **consecutive rows**, ask yourself:

> "How can I compare the current row with the rows immediately before or after it?"

Then choose:

```text
Self Join
    → compare rows using id/date relationships

LAG()
    → look at previous rows

LEAD()
    → look at following rows
```

For this problem, both approaches check whether **three consecutive rows contain the same number**.
