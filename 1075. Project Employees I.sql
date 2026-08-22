# 1075. Project Employees I

> **Difficulty:** Easy

## Problem

Find the **average experience years** of employees working on each project.

Round the average to **2 decimal places**.

Return the result table in **any order**.

### Table: Project

| Column | Type |
|--------|------|
| project_id | int |
| employee_id | int |

### Table: Employee

| Column | Type |
|--------|------|
| employee_id | int |
| name | varchar |
| experience_years | int |

---

## Solution 1: Using `INNER JOIN`

```sql
SELECT p.project_id,
       ROUND(AVG(e.experience_years), 2) AS average_years
FROM Project p
JOIN Employee e
ON p.employee_id = e.employee_id
GROUP BY p.project_id;
```

### Explanation

This solution joins the `Project` and `Employee` tables to retrieve the experience of every employee working on a project.

#### Step 1: Join the tables

```sql
FROM Project p
JOIN Employee e
ON p.employee_id = e.employee_id
```

The `JOIN` matches each employee assigned to a project with their corresponding record in the `Employee` table.

For example:

| project_id | employee_id | experience_years |
|------------|------------:|-----------------:|
| 1 | 1 | 3 |
| 1 | 2 | 2 |
| 1 | 3 | 1 |
| 2 | 1 | 3 |
| 2 | 4 | 2 |

Since `employee_id` in the `Project` table is a **foreign key** referencing the `Employee` table, every project assignment is guaranteed to have a matching employee.

#### Step 2: Group by project

```sql
GROUP BY p.project_id
```

This groups all employees working on the same project together.

For example:

**Project 1**

| experience_years |
|-----------------:|
| 3 |
| 2 |
| 1 |

**Project 2**

| experience_years |
|-----------------:|
| 3 |
| 2 |

#### Step 3: Calculate the average

```sql
AVG(e.experience_years)
```

`AVG()` calculates the average experience of employees within each project.

For example:

Project 1:

```
(3 + 2 + 1) / 3 = 2.00
```

Project 2:

```
(3 + 2) / 2 = 2.50
```

#### Step 4: Round the result

```sql
ROUND(..., 2)
```

rounds the average experience to **2 decimal places**.

Finally,

```sql
SELECT p.project_id,
       ROUND(AVG(e.experience_years), 2)
```

returns the required output.

> **Note:** An `INNER JOIN` is the most appropriate choice because every `employee_id` in the `Project` table is guaranteed to exist in the `Employee` table due to the foreign key constraint.

---

## Solution 2: Using `LEFT JOIN`

```sql
SELECT p.project_id,
       ROUND(AVG(e.experience_years), 2) AS average_years
FROM Project p
LEFT JOIN Employee e
ON p.employee_id = e.employee_id
GROUP BY p.project_id;
```

### Explanation

This solution uses a `LEFT JOIN` instead of an `INNER JOIN`.

- `Project` is used as the left table because the result should include every project assignment.
- The join matches each employee in the project with their experience.
- `AVG()` calculates the average experience for each project.
- `ROUND(..., 2)` rounds the result to two decimal places.

Since `employee_id` in the `Project` table is a **foreign key**, every project assignment has a matching employee. Therefore, `LEFT JOIN` produces the **same result** as `INNER JOIN`.

> **Note:** A foreign key does **not** automatically mean you should use an `INNER JOIN`. The choice of join depends on the problem requirements. In this problem, both `INNER JOIN` and `LEFT JOIN` return the same result because every project assignment has a matching employee record.
