# 1378. Replace Employee ID With The Unique Identifier

> **Difficulty:** Easy

## Problem

Display the **unique ID** and **name** of every employee.

- If an employee has a corresponding `unique_id`, display it.
- Otherwise, display `NULL`.

Return the result table in **any order**.

### Table: Employees

| Column | Type |
|--------|------|
| id | int |
| name | varchar |

### Table: EmployeeUNI

| Column | Type |
|--------|------|
| id | int |
| unique_id | int |

## Solution 1: Using `LEFT JOIN`

```sql
SELECT eu.unique_id, e.name
FROM Employees e
LEFT JOIN EmployeeUNI eu
ON e.id = eu.id;
```

### Explanation

A `LEFT JOIN` returns **all rows** from the left table (`Employees`) and the matching rows from the right table (`EmployeeUNI`).

- `Employees` is used as the left table because every employee must appear in the result.
- The join condition `e.id = eu.id` matches each employee with their corresponding unique ID.
- If an employee does not have a matching record in `EmployeeUNI`, the `unique_id` is automatically returned as `NULL`.

This satisfies the requirement of displaying every employee while showing `NULL` for those without a unique ID.

---

## Solution 2: Using `RIGHT JOIN`

```sql
SELECT eu.unique_id, e.name
FROM EmployeeUNI eu
RIGHT JOIN Employees e
ON eu.id = e.id;
```

### Explanation

A `RIGHT JOIN` returns **all rows** from the right table (`Employees`) and the matching rows from the left table (`EmployeeUNI`).

- `Employees` is placed on the right side of the join to ensure every employee appears in the result.
- The join condition `eu.id = e.id` matches employees with their unique IDs.
- If no matching record exists in `EmployeeUNI`, the `unique_id` is returned as `NULL`.

This produces the same result as the `LEFT JOIN` solution, but with the tables reversed.
