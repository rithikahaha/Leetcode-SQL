# 2356. Number of Unique Subjects Taught by Each Teacher

> **Difficulty:** Easy

## Problem

Calculate the number of **unique subjects** each teacher teaches in the university.

A teacher may teach the **same subject in multiple departments**, but that subject should only be counted **once** for that teacher.

Return the result table in **any order**.

### Table: Teacher

| Column | Type |
|--------|------|
| teacher_id | int |
| subject_id | int |
| dept_id | int |

---

## Solution 1: Using `COUNT(DISTINCT)`

```sql
SELECT teacher_id,
       COUNT(DISTINCT subject_id) AS cnt
FROM Teacher
GROUP BY teacher_id;
```

### Explanation

The key word in this problem is **"unique"**.

A teacher can teach the same subject in multiple departments, so simply using `COUNT(subject_id)` would count the same subject multiple times.

#### Step 1: Group by teacher

```sql
GROUP BY teacher_id
```

This creates a separate group for each teacher.

For example, Teacher 1 has:

| teacher_id | subject_id | dept_id |
|------------|------------|---------|
| 1 | 2 | 3 |
| 1 | 2 | 4 |
| 1 | 3 | 3 |

---

#### Step 2: Count unique subjects

```sql
COUNT(DISTINCT subject_id)
```

`DISTINCT` removes duplicate subject IDs **within each teacher's group**.

For Teacher 1:

```text
subject_id = 2, 2, 3
```

After `DISTINCT`:

```text
2, 3
```

Therefore:

```text
COUNT(DISTINCT subject_id) = 2
```

Even though Teacher 1 teaches subject 2 in **two different departments**, it is counted only once.

For Teacher 2:

```text
subject_id = 1, 2, 3, 4
```

All four subjects are unique, so:

```text
COUNT(DISTINCT subject_id) = 4
```

---

### Why not use `COUNT(subject_id)`?

If we wrote:

```sql
COUNT(subject_id)
```

Teacher 1 would get:

```text
2 + 2 + 3
↓
3
```

But the correct answer is `2` because subject `2` is taught in two departments but is still only **one unique subject**.

Therefore, whenever a problem asks for the number of **unique/distinct** values, think:

```sql
COUNT(DISTINCT column)
```

---

> **Note:** The primary key of the table is `(subject_id, dept_id)`, not `teacher_id`. This means the same teacher can appear multiple times for the same subject when the department is different. That is exactly why `COUNT(DISTINCT subject_id)` is necessary.

---

## Key Takeaway

This problem follows a very common SQL pattern:

```sql
SELECT group_column,
       COUNT(DISTINCT column)
FROM table
GROUP BY group_column;
```

Whenever you see:

> **"How many unique X does each Y have?"**

think:

```text
GROUP BY Y
       ↓
COUNT(DISTINCT X)
```
