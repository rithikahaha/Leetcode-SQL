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

## Solution: `CASE WHEN`

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

Three positive line segments can form a triangle only if:

> The sum of any two sides is greater than the third side.

So we need to check **all three possible combinations**.

---

## Step 1: Understand the Triangle Inequality

For three sides `x`, `y`, and `z`, we need:

```text
x + y > z
x + z > y
y + z > x
```

All three conditions must be true.

Why?

Imagine the longest side is `z`.

If:

```text
x + y <= z
```

then the two shorter sides are not long enough to meet and close the shape.

For example:

```text
x = 13
y = 15
z = 30
```

Check:

```text
13 + 15 > 30
28 > 30
```

This is false.

Therefore, these segments cannot form a triangle.

The answer is:

```text
No
```

---

## Step 2: Check All Three Conditions

We use:

```sql
x + y > z
AND x + z > y
AND y + z > x
```

The `AND` is important.

We don't just need **one** of the conditions to be true.

We need **every** condition to be true.

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

All three are true, so:

```text
Yes
```

---

## Step 3: Use `CASE`

We need to output either `'Yes'` or `'No'` depending on whether the conditions are satisfied.

This is exactly what `CASE` is designed for.

```sql
CASE
    WHEN condition
    THEN 'Yes'
    ELSE 'No'
END AS triangle
```

Think of it as:

```text
IF condition is true
    → Yes
ELSE
    → No
```

So our condition becomes:

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

## Why `CASE` instead of `WHERE`?

We are **not filtering rows out**.

The problem asks us to report **every row** and simply classify each row as `'Yes'` or `'No'`.

Therefore, we should not use:

```sql
WHERE ...
```

because `WHERE` would remove rows that don't satisfy the condition.

Instead, we use `CASE` to create a new column:

```text
triangle
```

For example:

|  x |  y |  z | triangle |
| -: | -: | -: | -------- |
| 13 | 15 | 30 | No       |
| 10 | 20 | 15 | Yes      |

Both rows remain in the result.

---

## Why `AND` instead of `OR`?

This is another important detail.

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

`OR` would incorrectly allow a row where only one or two conditions are true.

For a triangle, **all three conditions must be satisfied**.

So:

```text
AND → every condition must be true
OR  → at least one condition must be true
```

Here we need `AND`.

---

## Why is the condition `>` and not `>=`?

The rule is:

```text
sum of two sides > third side
```

It must be **strictly greater**.

Consider:

```text
x = 3
y = 4
z = 7
```

We get:

```text
3 + 4 = 7
```

The sides cannot form a proper triangle because they would lie in a straight line rather than creating a closed triangle.

Therefore:

```sql
x + y > z
```

is correct.

Using:

```sql
x + y >= z
```

would incorrectly classify this case as a triangle.

---

## Breaking Down the Full Query

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

Let's read it piece by piece.

### Select the original sides

```sql
SELECT x,
       y,
       z
```

We need to return the three original side lengths.

### Create the result column

```sql
CASE
    WHEN ...
    THEN 'Yes'
    ELSE 'No'
END AS triangle
```

This creates a new column called `triangle`.

### Check the triangle inequality

```sql
x + y > z
AND x + z > y
AND y + z > x
```

This determines whether the three lengths can form a triangle.

### Read from the table

```sql
FROM Triangle
```

We perform this calculation for every row in the table.

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

Check:

```text
13 + 15 > 30
28 > 30 → FALSE
```

Since one condition is false:

```text
triangle = No
```

---

### Row 2

```text
x = 10
y = 20
z = 15
```

Check:

```text
10 + 20 > 15 → TRUE
10 + 15 > 20 → TRUE
20 + 15 > 10 → TRUE
```

All conditions are true:

```text
triangle = Yes
```

So the final result is:

|  x |  y |  z | triangle |
| -: | -: | -: | -------- |
| 13 | 15 | 30 | No       |
| 10 | 20 | 15 | Yes      |

---

## A Useful Alternative: Check the Largest Side Only

Mathematically, we can also check whether the **largest side** is smaller than the sum of the other two sides.

For example, if `z` is the largest:

```text
x + y > z
```

But since we don't know which of `x`, `y`, or `z` is largest, we'd need to use `GREATEST()` and `SUM`-like logic.

For this problem, explicitly checking all three conditions is much simpler and easier to understand:

```sql
x + y > z
AND x + z > y
AND y + z > x
```

---

## Key Takeaway

When a SQL problem asks you to **classify each row** based on a condition, think about:

```sql
CASE
    WHEN condition
    THEN 'Yes'
    ELSE 'No'
END
```

For the Triangle Judgement problem, the condition is the triangle inequality:

```text
x + y > z
AND
x + z > y
AND
y + z > x
```

So the general pattern is:

```sql
SELECT ...,
       CASE
           WHEN condition1
            AND condition2
            AND condition3
           THEN 'Yes'
           ELSE 'No'
       END AS result
FROM table;
```

The important concepts here are:

* **Triangle inequality** → determines whether three lengths form a triangle.
* `CASE WHEN` → creates a conditional result for every row.
* `AND` → requires all three conditions to be true.
* `>` → must be strictly greater; equality does not form a triangle.
* `WHERE` is not appropriate because we need to keep **both** valid and invalid rows.
