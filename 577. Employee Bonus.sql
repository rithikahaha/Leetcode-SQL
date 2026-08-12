# 577. Employee Bonus

> **Difficulty:** Easy

## Problem

Report the **name** and **bonus** of each employee who:

- Has a bonus **less than 1000**, or
- Did **not receive a bonus**.

Return the result table in **any order**.

### Table: Employee

| Column | Type |
|--------|------|
| empId | int |
| name | varchar |
| supervisor | int |
| salary | int |

### Table: Bonus

| Column | Type |
|--------|------|
| empId | int |
| bonus | int |

## Solution 1: Using `LEFT JOIN`

```sql
SELECT e.name, b.bonus
FROM Employee e
LEFT JOIN Bonus b
ON e.empId = b.empId
WHERE b.bonus < 1000
   OR b.bonus IS NULL;
```

### Explanation

A `LEFT JOIN` returns **all employees** from the `Employee` table and the matching bonus information from the `Bonus` table.

- `Employee` is used as the left table because every employee should be considered.
- The join condition `e.empId = b.empId` matches each employee with their bonus.
- If an employee does not have a matching row in the `Bonus` table, `bonus` is returned as `NULL`.
- The `WHERE` clause filters employees who:
  - have a bonus less than `1000`, or
  - have no bonus (`NULL`).

> **Note:** Since `empId` in the `Bonus` table is a foreign key, every bonus belongs to a valid employee. However, not every employee is guaranteed to have a bonus. Therefore, a `LEFT JOIN` is required to include employees without matching bonus records.

---

## Solution 2: Using `RIGHT JOIN`

```sql
SELECT e.name, b.bonus
FROM Bonus b
RIGHT JOIN Employee e
ON b.empId = e.empId
WHERE b.bonus < 1000
   OR b.bonus IS NULL;
```

### Explanation

A `RIGHT JOIN` returns **all employees** from the right table (`Employee`) and the matching bonus information from the left table (`Bonus`).

- `Employee` is placed on the right so that every employee appears in the result.
- The join condition matches employees with their bonuses.
- If an employee has no bonus record, the `bonus` column is returned as `NULL`.
- The `WHERE` clause keeps employees whose bonus is less than `1000` or whose bonus is `NULL`.

This produces the same result as the `LEFT JOIN` solution, with the tables reversed.

---

## Solution 3: Using `IFNULL()`

```sql
SELECT e.name, b.bonus
FROM Employee e
LEFT JOIN Bonus b
ON e.empId = b.empId
WHERE IFNULL(b.bonus, 0) < 1000;
```

### Explanation

The `IFNULL()` function replaces `NULL` values with `0`.

- If an employee has no bonus, `IFNULL(b.bonus, 0)` becomes `0`.
- Since `0 < 1000`, employees without a bonus are included.
- Employees with a bonus less than `1000` are also included.
- Employees with a bonus of `1000` or more are excluded.

Using `IFNULL()` provides a concise way to handle `NULL` values without writing an additional `OR b.bonus IS NULL` condition.

> **Note:** `IFNULL()` is specific to MySQL. If you're writing SQL that should work across multiple database systems, consider using `COALESCE()` instead.

---

## Solution 4: Using `COALESCE()`

```sql
SELECT e.name, b.bonus
FROM Employee e
LEFT JOIN Bonus b
ON e.empId = b.empId
WHERE COALESCE(b.bonus, 0) < 1000;
```

### Explanation

The `COALESCE()` function returns the first non-`NULL` value from its list of arguments.

- If `bonus` is `NULL`, `COALESCE(b.bonus, 0)` returns `0`.
- Since `0 < 1000`, employees without a bonus are included.
- Employees with a bonus less than `1000` are also included.
- Employees with a bonus of `1000` or more are excluded.

Using `COALESCE()` provides a concise and portable way to handle `NULL` values.

> **Note:** Unlike `IFNULL()`, `COALESCE()` is part of the SQL standard and is supported by most relational database systems.
