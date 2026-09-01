# 596. Classes With at Least 5 Students

> **Difficulty:** Easy

## Problem

Find all classes that have **at least five students**.

Return the result table in **any order**.

### Table: `Courses`

| Column | Type |
|--------|------|
| student | varchar |
| class | varchar |

`(student, class)` is the primary key, meaning the same student cannot be enrolled in the same class more than once.

---

## Solution: Using `GROUP BY` and `HAVING`

```sql
SELECT class
FROM Courses
GROUP BY class
HAVING COUNT(student) >= 5;
```

### Explanation

The main goal is to:

1. Group students according to their class.
2. Count how many students are in each class.
3. Keep only the classes with at least 5 students.

---

### Step 1: Group the rows by class

```sql
GROUP BY class
```

We want to know the number of students **for each class**, so we group all rows with the same `class` together.

For example, the original table contains:

| student | class |
|---------|-------|
| A | Math |
| B | English |
| C | Math |
| D | Biology |
| E | Math |
| F | Computer |
| G | Math |
| H | Math |
| I | Math |

After grouping by `class`, we conceptually have:

```text
Math
├── A
├── C
├── E
├── G
├── H
└── I

English
└── B

Biology
└── D

Computer
└── F
```

So each class now represents a group of students.

---

### Step 2: Count the students in each class

```sql
COUNT(student)
```

`COUNT(student)` counts the number of non-`NULL` values in the `student` column within each group.

Therefore:

```text
Math     → 6
English  → 1
Biology  → 1
Computer → 1
```

For example, the `Math` group contains:

```text
A, C, E, G, H, I
```

so:

```text
COUNT(student) = 6
```

---

### Step 3: Keep only classes with at least 5 students

```sql
HAVING COUNT(student) >= 5
```

Now we filter the groups based on their student count.

The condition:

```sql
COUNT(student) >= 5
```

means:

> Keep the class if it has 5 or more students.

Therefore:

| class | student count | Keep? |
|-------|--------------:|-------|
| Math | 6 | Yes |
| English | 1 | No |
| Biology | 1 | No |
| Computer | 1 | No |

Only `Math` remains.

---

## Why do we use `HAVING` instead of `WHERE`?

This is one of the most important concepts in this problem.

We might initially think of writing:

```sql
WHERE COUNT(student) >= 5
```

But this is **invalid SQL**.

The reason is that `WHERE` filters individual rows **before** the grouping and aggregation happens.

The SQL processing conceptually happens in this order:

```text
FROM
  ↓
WHERE
  ↓
GROUP BY
  ↓
HAVING
  ↓
SELECT
  ↓
ORDER BY
```

`COUNT(student)` is calculated **after the rows have been grouped**.

Therefore, we cannot use the aggregate result inside `WHERE`.

Instead, we use:

```sql
HAVING COUNT(student) >= 5
```

because `HAVING` filters the groups **after aggregation**.

### Easy way to remember

`WHERE` → filters **rows**

```sql
WHERE salary > 50000
```

`HAVING` → filters **groups**

```sql
HAVING COUNT(*) >= 5
```

So whenever the condition contains an aggregate function such as:

```sql
COUNT()
SUM()
AVG()
MIN()
MAX()
```

you should generally think of `HAVING`.

---

## `COUNT(student)` vs `COUNT(*)`

We can also write the query as:

```sql
SELECT class
FROM Courses
GROUP BY class
HAVING COUNT(*) >= 5;
```

This produces the same result for this problem.

### `COUNT(student)`

```sql
COUNT(student)
```

counts the number of **non-`NULL` values** in the `student` column.

### `COUNT(*)`

```sql
COUNT(*)
```

counts **every row** in the group, regardless of whether individual columns contain `NULL`.

For example, if a group contained:

| student |
|---------|
| A |
| B |
| NULL |

then:

```sql
COUNT(student) = 2
```

while:

```sql
COUNT(*) = 3
```

In this problem, each row represents a student enrollment and `student` is not `NULL`, so both approaches give the same result.

> **Rule to remember:**
>
> ```sql
> COUNT(*)              → counts rows
> COUNT(column)         → counts non-NULL values
> COUNT(DISTINCT column) → counts unique non-NULL values
> ```

---

## Why don't we use `COUNT(DISTINCT student)`?

You might wonder whether we need:

```sql
COUNT(DISTINCT student)
```

instead of:

```sql
COUNT(student)
```

The table has:

```text
(student, class)
```

as its primary key.

This means the combination of a student and class must be unique.

Therefore, a student cannot appear twice for the same class.

For example, this would not be allowed:

| student | class |
|---------|-------|
| A | Math |
| A | Math |

So every row represents a unique enrollment.

Therefore:

```sql
COUNT(student)
```

already gives us the number of unique students in each class.

If duplicate student-class rows were possible, then we would need:

```sql
COUNT(DISTINCT student)
```

to avoid counting the same student multiple times.

---

## Why don't we need `ORDER BY`?

The problem says:

> Return the result table in any order.

Therefore, no sorting is required.

The query:

```sql
SELECT class
FROM Courses
GROUP BY class
HAVING COUNT(student) >= 5;
```

is sufficient.

If the problem required the classes to be sorted alphabetically, we could add:

```sql
ORDER BY class;
```

---

## Query Breakdown

The complete query:

```sql
SELECT class
FROM Courses
GROUP BY class
HAVING COUNT(student) >= 5;
```

can be read almost like English:

```text
FROM Courses
    ↓
Take the Courses table

GROUP BY class
    ↓
Put students belonging to the same class together

COUNT(student)
    ↓
Count the students in each class

HAVING COUNT(student) >= 5
    ↓
Keep only classes with at least 5 students

SELECT class
    ↓
Return the class names
```

---

## Key Takeaway

This problem follows a very common SQL pattern:

```sql
SELECT group_column
FROM table
GROUP BY group_column
HAVING COUNT(*) >= condition;
```

Whenever you see a question asking:

- Which classes have at least 5 students?
- Which departments have more than 10 employees?
- Which customers have made at least 3 orders?
- Which products have been purchased more than 100 times?

Think:

```text
GROUP BY
   ↓
COUNT()
   ↓
HAVING
```

### Pattern to remember

```sql
SELECT group_column,
       COUNT(*)
FROM table
GROUP BY group_column
HAVING COUNT(*) >= n;
```

The most important distinction is:

```text
WHERE  → filter individual rows
HAVING → filter groups after aggregation
```
