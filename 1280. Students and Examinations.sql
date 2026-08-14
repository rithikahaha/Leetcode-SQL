# 1280. Students and Examinations

> **Difficulty:** Easy

## Problem

Find the number of times each student attended each subject's exam.

The result should include **every possible student-subject combination**, even if a student never attended a particular exam.

Return the result table ordered by **`student_id`** and **`subject_name`**.

### Table: Students

| Column | Type |
|--------|------|
| student_id | int |
| student_name | varchar |

### Table: Subjects

| Column | Type |
|--------|------|
| subject_name | varchar |

### Table: Examinations

| Column | Type |
|--------|------|
| student_id | int |
| subject_name | varchar |

---

## Solution 1: Using `CROSS JOIN` and `LEFT JOIN`

```sql
SELECT s.student_id,
       s.student_name,
       sub.subject_name,
       COUNT(e.subject_name) AS attended_exams
FROM Students s
CROSS JOIN Subjects sub
LEFT JOIN Examinations e
ON s.student_id = e.student_id
AND sub.subject_name = e.subject_name
GROUP BY s.student_id,
         s.student_name,
         sub.subject_name
ORDER BY s.student_id,
         sub.subject_name;
```

### Explanation

This solution uses a combination of **`CROSS JOIN`** and **`LEFT JOIN`**.

#### Step 1: Generate every student-subject combination

```sql
Students
CROSS JOIN
Subjects
```

A `CROSS JOIN` creates the Cartesian product of both tables.

If there are:

- 4 students
- 3 subjects

the result contains:

```
4 × 3 = 12 rows
```

For example:

| student_id | student_name | subject_name |
|------------|--------------|--------------|
| 1 | Alice | Math |
| 1 | Alice | Physics |
| 1 | Alice | Programming |
| 2 | Bob | Math |
| ... | ... | ... |

This guarantees that **every student appears with every subject**, even if they never attended an exam.

#### Step 2: Match the examinations

```sql
LEFT JOIN Examinations
ON s.student_id = e.student_id
AND sub.subject_name = e.subject_name
```

The `LEFT JOIN` matches each student-subject combination with the corresponding exam records.

- If matching exam records exist, they are joined.
- If no matching exam exists, the columns from `Examinations` become `NULL`.

Using a `LEFT JOIN` ensures that combinations with **zero exams** are still included.

#### Step 3: Count the exams

```sql
COUNT(e.subject_name)
```

counts the number of matching examination records.

For example:

| student | subject | matching rows | count |
|---------|---------|---------------|------:|
| Alice | Math | 3 | 3 |
| Bob | Physics | 0 | 0 |
| Alex | Programming | 0 | 0 |

Since `COUNT(column)` ignores `NULL` values, combinations with no matching exam records automatically receive a count of **0**.

> **Note:** `COUNT(*)` should **not** be used here. After the `CROSS JOIN`, every student-subject combination already exists as a row, so `COUNT(*)` would count that row even when no matching examination exists. Using `COUNT(e.subject_name)` counts only the matching examination records because `NULL` values are ignored.

#### Step 4: Group the results

```sql
GROUP BY
s.student_id,
s.student_name,
sub.subject_name
```

groups all examination records belonging to the same student and subject together so that `COUNT()` can calculate the total number of attended exams.

#### Step 5: Sort the output

```sql
ORDER BY
student_id,
subject_name
```

returns the result in the required order.

> **Note:** A `CROSS JOIN` is the key to this problem. Without it, students who never attended a particular subject (or never attended any exam at all) would not appear in the result.
