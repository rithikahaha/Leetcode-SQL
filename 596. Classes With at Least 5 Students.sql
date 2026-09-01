# 596. Classes With at Least 5 Students

> **Difficulty:** Easy

## Problem

Find all classes that have **at least five students**.

Return the result table in **any order**.

### Table: Courses

| Column | Type |
|--------|------|
| student | varchar |
| class | varchar |

---

## Solution 1: Using `GROUP BY` and `HAVING`

```sql
SELECT class
FROM Courses
GROUP BY class
HAVING COUNT(student) >= 5;
