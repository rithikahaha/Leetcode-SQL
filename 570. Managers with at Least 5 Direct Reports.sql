# 570. Managers with at Least 5 Direct Reports

> **Difficulty:** Medium

## Problem

Find the names of managers who have **at least five direct reports**.

Return the result table in **any order**.

### Table: Employee

| Column | Type |
|--------|------|
| id | int |
| name | varchar |
| department | varchar |
| managerId | int |

---

## Solution 1: Using `INNER JOIN`

```sql
SELECT m.name
FROM Employee e
JOIN Employee m
ON e.managerId = m.id
GROUP BY m.id, m.name
HAVING COUNT(*) >= 5;
```

### Explanation

This solution uses a **self join** because both employees and managers are stored in the same table.

#### Step 1: Join employees with their managers

```sql
Employee e
JOIN Employee m
ON e.managerId = m.id
```

- `e` represents the **employee**.
- `m` represents the **manager**.
- The join condition matches each employee with their manager using:

```sql
e.managerId = m.id
```

For example:

| Employee | Manager |
|----------|---------|
| Dan | John |
| James | John |
| Amy | John |
| Anne | John |
| Ron | John |

#### Step 2: Group by manager

```sql
GROUP BY
m.id,
m.name
```

This groups all employees reporting to the same manager.

#### Step 3: Count direct reports

```sql
HAVING COUNT(*) >= 5
```

`COUNT(*)` counts the number of employees in each manager's group.

Managers with **five or more direct reports** satisfy the condition.

Finally,

```sql
SELECT m.name
```

returns the manager's name.

> **Note:** `HAVING` is used instead of `WHERE` because the filtering is performed **after** grouping and aggregation.

---

## Solution 2: Using a Subquery

```sql
SELECT name
FROM Employee
WHERE id IN (
    SELECT managerId
    FROM Employee
    WHERE managerId IS NOT NULL
    GROUP BY managerId
    HAVING COUNT(*) >= 5
);
```

### Explanation

This solution first identifies managers with at least five direct reports, then retrieves their names.

#### Step 1: Find manager IDs

```sql
SELECT managerId
FROM Employee
WHERE managerId IS NOT NULL
GROUP BY managerId
HAVING COUNT(*) >= 5
```

- Employees are grouped by `managerId`.
- `COUNT(*)` counts how many employees report to each manager.
- `HAVING COUNT(*) >= 5` keeps only managers with at least five direct reports.

This produces a list of manager IDs.

#### Step 2: Retrieve the manager names

```sql
SELECT name
FROM Employee
WHERE id IN (...)
```

The outer query selects the names of employees whose `id` appears in the list of manager IDs returned by the subquery.

> **Note:** `WHERE managerId IS NOT NULL` excludes employees who do not have a manager. While `GROUP BY` would naturally ignore `NULL` as a valid manager ID for this problem, including this condition makes the intent of the query clearer.
