# 610. Triangle Judgement

> **Difficulty:** Easy

## Problem

You are given a `Triangle` table containing the lengths of three line segments.

### Table: `Triangle`

| Column | Type |
| ------ | ---- |
| `x`    | int  |
| `y`    | int  |
| `z`    | int  |

* `(x, y, z)` is the primary key.
* Each row contains three line segment lengths.
* For each row, determine whether the three segments can form a triangle.

Return the original three lengths along with `triangle`, which should be:

* `'Yes'` if the three sides can form a triangle.
* `'No'` otherwise.

---

## Solution 1: `CASE WHEN`

```sql
SELECT x,
       y,
       z,
       CASE
           WHEN x + y > z
            AND x + z > y
            AND y + z > x
           THEN 'Yes'
           ELSE 'No'
       END AS triangle
FROM Triangle;
```

### Explanation

The key to this problem is the **triangle inequality**.

Three line segments can form a triangle only if the sum of **any two sides is greater than the third side**.

So we need to check all three possible combinations:

```text
x + y > z
x + z > y
y + z > x
```

All three conditions must be true.

---

### Step 1: Understand the Triangle Inequality

For three sides `x`, `y`, and `z`, we need:

```text
x + y > z
x + z > y
y + z > x
```

For example:

```text
x = 10
y = 20
z = 15
```

Check:

```text
10 + 20 > 15  → TRUE
10 + 15 > 20  → TRUE
20 + 15 > 10  → TRUE
```

All three conditions are true, so these sides can form a triangle.

The answer is:

```text
Yes
```

Now consider:

```text
x = 13
y = 15
z = 30
```

Check:

```text
13 + 15 > 30
28 > 30 → FALSE
```

Since one condition is false, the three sides cannot form a triangle.

The answer is:

```text
No
```

---

### Step 2: Use `CASE`

We need to output either `'Yes'` or `'No'` depending on whether the conditions are satisfied.

This is what `CASE` is designed for:

```sql
CASE
    WHEN condition
    THEN 'Yes'
    ELSE 'No'
END
```

It works like:

```text
IF condition is true
    → Yes
ELSE
    → No
```

So we write:

```sql
CASE
    WHEN x + y > z
     AND x + z > y
     AND y + z > x
    THEN 'Yes'
    ELSE 'No'
END AS triangle
```

---

### Why `AND` instead of `OR`?

We need:

```sql
x + y > z
AND x + z > y
AND y + z > x
```

not:

```sql
x + y > z
OR x + z > y
OR y + z > x
```

`AND` means **every condition must be true**.

`OR` means **at least one condition must be true**.

For a valid triangle, all three conditions must be satisfied.

---

### Why `>` instead of `>=`?

The condition must use `>` rather than `>=`.

For example:

```text
x = 3
y = 4
z = 7
```

Here:

```text
3 + 4 = 7
```

The sides would form a straight line rather than a proper triangle.

Therefore:

```sql
x + y > z
```

is correct.

Using:

```sql
x + y >= z
```

would incorrectly classify this as a triangle.

---

## Solution 2: `IF()`

MySQL also provides the `IF()` function, which is useful when there are only **two possible outcomes**.

```sql
SELECT x,
       y,
       z,
       IF(
           x + y > z
           AND x + z > y
           AND y + z > x,
           'Yes',
           'No'
       ) AS triangle
FROM Triangle;
```

### Explanation

`IF()` in MySQL follows this structure:

```sql
IF(condition, value_if_true, value_if_false)
```

You can think of it as:

```text
IF(condition)
    → return value_if_true
ELSE
    → return value_if_false
```

For this problem:

```sql
IF(
    condition,
    'Yes',
    'No'
)
```

means:

```text
IF the sides can form a triangle
    → return 'Yes'
ELSE
    → return 'No'
```

---

### Step 1: Write the condition

The condition is exactly the same as in the `CASE` solution:

```sql
x + y > z
AND x + z > y
AND y + z > x
```

This checks the triangle inequality.

---

### Step 2: Put the condition inside `IF()`

The general structure is:

```sql
IF(
    condition,
    'Yes',
    'No'
)
```

So:

```sql
IF(
    x + y > z
    AND x + z > y
    AND y + z > x,
    'Yes',
    'No'
)
```

The three arguments are:

```text
1st argument → condition
2nd argument → what to return if TRUE
3rd argument → what to return if FALSE
```

Specifically:

```text
condition
    ↓
x + y > z
AND x + z > y
AND y + z > x

TRUE
    ↓
'Yes'

FALSE
    ↓
'No'
```

---

## `CASE WHEN` vs `IF()`

Both solutions produce the same result.

### `IF()`

```sql
IF(condition, 'Yes', 'No')
```

This is shorter and convenient when there are only two possible outcomes.

### `CASE`

```sql
CASE
    WHEN condition THEN 'Yes'
    ELSE 'No'
END
```

`CASE` is more flexible when there are multiple conditions or multiple possible outputs.

For example:

```sql
CASE
    WHEN score >= 90 THEN 'A'
    WHEN score >= 80 THEN 'B'
    WHEN score >= 70 THEN 'C'
    ELSE 'F'
END
```

That would be much harder to express cleanly with nested `IF()` statements.

For this particular problem, however, both are perfectly reasonable.

---

## Why `IF()` works well for this problem

The question only has two possible results:

```text
Yes
No
```

So the logic naturally fits:

```sql
IF(condition, 'Yes', 'No')
```

This makes the `IF()` version particularly concise:

```sql
SELECT x,
       y,
       z,
       IF(
           x + y > z
           AND x + z > y
           AND y + z > x,
           'Yes',
           'No'
       ) AS triangle
FROM Triangle;
```

---

## Why not use `WHERE`?

We should **not** write:

```sql
WHERE x + y > z
  AND x + z > y
  AND y + z > x
```

because `WHERE` would remove the rows that do not form triangles.

The problem asks us to report **every row**, while simply labeling each one as `'Yes'` or `'No'`.

For example:

|  x |  y |  z |
| -: | -: | -: |
| 13 | 15 | 30 |
| 10 | 20 | 15 |

We need:

|  x |  y |  z | triangle |
| -: | -: | -: | -------- |
| 13 | 15 | 30 | No       |
| 10 | 20 | 15 | Yes      |

The invalid triangle still needs to appear.

Therefore, we use `IF()` or `CASE` to **create a result column**, rather than `WHERE` to filter rows.

---

## Breaking Down the `IF()` Query

```sql
SELECT x,
       y,
       z,
       IF(
           x + y > z
           AND x + z > y
           AND y + z > x,
           'Yes',
           'No'
       ) AS triangle
FROM Triangle;
```

Think about it in this order:

### 1. Return the original side lengths

```sql
SELECT x, y, z
```

### 2. Check whether they form a triangle

```sql
x + y > z
AND x + z > y
AND y + z > x
```

### 3. If true, return `'Yes'`

```sql
'Yes'
```

### 4. If false, return `'No'`

```sql
'No'
```

### 5. Give the calculated column a name

```sql
AS triangle
```

---

## Example Walkthrough

Given:

|  x |  y |  z |
| -: | -: | -: |
| 13 | 15 | 30 |
| 10 | 20 | 15 |

### Row 1

```text
x = 13
y = 15
z = 30
```

The condition becomes:

```text
13 + 15 > 30
28 > 30 → FALSE
```

Therefore:

```text
IF(FALSE, 'Yes', 'No')
```

returns:

```text
No
```

---

### Row 2

```text
x = 10
y = 20
z = 15
```

The condition becomes:

```text
10 + 20 > 15 → TRUE
10 + 15 > 20 → TRUE
20 + 15 > 10 → TRUE
```

Therefore:

```text
IF(TRUE, 'Yes', 'No')
```

returns:

```text
Yes
```

Final result:

|  x |  y |  z | triangle |
| -: | -: | -: | -------- |
| 13 | 15 | 30 | No       |
| 10 | 20 | 15 | Yes      |

---

## Key Takeaway

When a SQL problem asks you to **classify every row** based on a condition, two useful options are:

### `IF()`

```sql
IF(condition, value_if_true, value_if_false)
```

Use this when there are two straightforward outcomes.

### `CASE`

```sql
CASE
    WHEN condition THEN value
    ELSE value
END
```

Use this when you have multiple conditions or more complex logic.

For this problem:

```sql
IF(
    x + y > z
    AND x + z > y
    AND y + z > x,
    'Yes',
    'No'
)
```

means:

```text
IF all three triangle conditions are true
    → Yes
ELSE
    → No
```

The main concepts to remember are:

* **Triangle inequality** → the sum of any two sides must be greater than the third.
* `IF()` → returns one value when a condition is true and another when it is false.
* `CASE WHEN` → another way to implement conditional logic.
* `AND` → all three triangle conditions must be true.
* `>` → equality does not form a proper triangle.
* `WHERE` → should not be used because we need to keep both `'Yes'` and `'No'` rows.
