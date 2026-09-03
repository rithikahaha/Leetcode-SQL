# 1789. Primary Department for Each Employee

> **Difficulty:** Easy

## Problem

You are given an `Employee` table that shows which departments each employee belongs to and whether a department is their primary department.

### Table: `Employee`

| Column          | Type    |
| --------------- | ------- |
| `employee_id`   | int     |
| `department_id` | int     |
| `primary_flag`  | varchar |

* `(employee_id, department_id)` is the primary key, so each employee-department combination is unique.
* `employee_id` identifies the employee.
* `department_id` identifies the department the employee belongs to.
* `primary_flag` is either `'Y'` or `'N'`.

  * `'Y'` → this is the employee's primary department.
  * `'N'` → this is not the primary department.

An employee can belong to multiple departments.

If an employee belongs to **only one department**, their `primary_flag` will be `'N'`. In that case, their only department should be considered their primary department.

Return the `employee_id` and `department_id` of every employee's primary department.

The result can be returned in any order.

---

## Solution: `OR` Condition

```sql
SELECT employee_id, department_id
FROM Employee
WHERE primary_flag = 'Y'
   OR employee_id IN (
       SELECT employee_id
       FROM Employee
       GROUP BY employee_id
       HAVING COUNT(*) = 1
   );
```

### Explanation

There are **two possible cases** for each employee:

1. The employee belongs to multiple departments → choose the department where `primary_flag = 'Y'`.
2. The employee belongs to only one department → choose that department, even though its flag is `'N'`.

So we need to handle both cases.

---

## Step 1: Find employees with a primary department

For employees who belong to multiple departments, the primary department is explicitly marked:

```sql
primary_flag = 'Y'
```

So:

```sql
WHERE primary_flag = 'Y'
```

will find those departments.

For example:

| employee_id | department_id | primary_flag |
| ----------: | ------------: | ------------ |
|           2 |             1 | Y            |
|           2 |             2 | N            |

Employee `2` belongs to two departments, and department `1` is marked `'Y'`.

Therefore, we return:

```text
employee_id = 2
department_id = 1
```

---

## Step 2: Handle employees with only one department

The tricky part is that an employee who belongs to only one department has:

```text
primary_flag = 'N'
```

For example:

| employee_id | department_id | primary_flag |
| ----------: | ------------: | ------------ |
|           1 |             1 | N            |

If we only used:

```sql
WHERE primary_flag = 'Y'
```

employee `1` would be missing.

But the problem tells us that if an employee belongs to only one department, **that department is the one we should return**.

So we need to identify employees who appear only once.

---

## Step 3: Count departments for each employee

We can group the table by employee:

```sql
SELECT employee_id
FROM Employee
GROUP BY employee_id
```

This creates one group for each employee.

Then:

```sql
COUNT(*)
```

counts how many department rows each employee has.

For example:

| employee_id | department_id |
| ----------: | ------------: |
|           1 |             1 |
|           2 |             1 |
|           2 |             2 |
|           3 |             3 |
|           4 |             2 |
|           4 |             3 |
|           4 |             4 |

The counts are:

| employee_id | department count |
| ----------: | ---------------: |
|           1 |                1 |
|           2 |                2 |
|           3 |                1 |
|           4 |                3 |

---

## Step 4: Keep employees with exactly one department

We use:

```sql
HAVING COUNT(*) = 1
```

So:

```sql
SELECT employee_id
FROM Employee
GROUP BY employee_id
HAVING COUNT(*) = 1
```

returns:

```text
1
3
```

These are the employees who belong to only one department.

---

## Why `HAVING` instead of `WHERE`?

We use:

```sql
HAVING COUNT(*) = 1
```

because `COUNT(*)` is an aggregate function calculated **after grouping**.

`WHERE` filters individual rows **before** `GROUP BY`.

`HAVING` filters the resulting groups **after** aggregation.

So this is valid:

```sql
GROUP BY employee_id
HAVING COUNT(*) = 1
```

but this is not:

```sql
WHERE COUNT(*) = 1
```

---

## Step 5: Use `IN` to include those employees

The subquery:

```sql
SELECT employee_id
FROM Employee
GROUP BY employee_id
HAVING COUNT(*) = 1
```

gives us the IDs of employees who belong to exactly one department.

We then use:

```sql
employee_id IN (...)
```

to include their department.

The complete condition is:

```sql
WHERE primary_flag = 'Y'
   OR employee_id IN (
       SELECT employee_id
       FROM Employee
       GROUP BY employee_id
       HAVING COUNT(*) = 1
   )
```

This means:

> Return the row if it is explicitly marked as primary **OR** if the employee belongs to only one department.

---

## Understanding the `OR`

This is the core logic of the problem:

```sql
primary_flag = 'Y'
OR
employee has only one department
```

Let's look at each employee from the example.

### Employee 1

```text
1 → Department 1 → N
```

Only one department.

Therefore, return:

```text
1 | 1
```

---

### Employee 2

```text
2 → Department 1 → Y
2 → Department 2 → N
```

Multiple departments, so we use the `'Y'` row.

Return:

```text
2 | 1
```

---

### Employee 3

```text
3 → Department 3 → N
```

Only one department.

Therefore, return:

```text
3 | 3
```

---

### Employee 4

```text
4 → Department 2 → N
4 → Department 3 → Y
4 → Department 4 → N
```

Multiple departments, so we use the `'Y'` row.

Return:

```text
4 | 3
```

---

## Why doesn't the `OR` return extra rows?

This is an important detail.

Consider employee `2`:

| employee_id | department_id | primary_flag |
| ----------: | ------------: | ------------ |
|           2 |             1 | Y            |
|           2 |             2 | N            |

Employee `2` does **not** satisfy:

```sql
employee_id IN (
    SELECT employee_id
    ...
    HAVING COUNT(*) = 1
)
```

because employee `2` belongs to two departments.

Therefore, only the row with:

```text
primary_flag = 'Y'
```

is returned.

For an employee with multiple departments, only the primary row qualifies.

For an employee with one department, that single row qualifies through the second condition.

---

# Alternative Solution: `UNION`

We can also solve the two cases separately using `UNION`.

```sql
SELECT employee_id, department_id
FROM Employee
WHERE primary_flag = 'Y'

UNION

SELECT employee_id, department_id
FROM Employee
GROUP BY employee_id, department_id
HAVING COUNT(*) = 1;
```

### Explanation

The first query handles employees who have an explicitly marked primary department:

```sql
SELECT employee_id, department_id
FROM Employee
WHERE primary_flag = 'Y'
```

The second query handles employees who belong to only one department.

Because `(employee_id, department_id)` is the primary key, grouping by both columns and counting rows doesn't directly identify employees with only one department in the same useful way. A clearer version is to first identify single-department employees:

```sql
SELECT employee_id
FROM Employee
GROUP BY employee_id
HAVING COUNT(*) = 1
```

and then retrieve their department.

So the `OR` solution is generally easier to read for this problem.

---

## A More Direct Way to Think About the Problem

Before writing SQL, translate the problem into two rules:

```text
IF employee has a primary_flag = 'Y'
    → return that department

ELSE IF employee has only one department
    → return that department
```

Then convert those rules into SQL:

```sql
WHERE primary_flag = 'Y'
   OR employee_id IN (
       ...
       HAVING COUNT(*) = 1
   )
```

This is a useful way to approach SQL problems where different rows follow different conditions.

---

## Key Takeaway

The main solution is:

```sql
SELECT employee_id, department_id
FROM Employee
WHERE primary_flag = 'Y'
   OR employee_id IN (
       SELECT employee_id
       FROM Employee
       GROUP BY employee_id
       HAVING COUNT(*) = 1
   );
```

The key concepts are:

* `primary_flag = 'Y'` → finds explicitly selected primary departments.
* `GROUP BY employee_id` → examines each employee separately.
* `COUNT(*) = 1` → identifies employees belonging to exactly one department.
* `HAVING` → filters employees based on the department count.
* `IN` → checks whether an employee belongs to the single-department group.
* `OR` → combines the two possible cases.

### The main pattern to remember

When a problem says:

> "Use condition A, but if the entity has only one option, use that option."

Think:

```text
condition A
    OR
entity has exactly one row
```

For this problem:

```text
primary_flag = 'Y'
        OR
department count = 1
```
