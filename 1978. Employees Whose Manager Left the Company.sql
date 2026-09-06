# 1978. Employees Whose Manager Left the Company

> **Difficulty:** Easy

## Problem

You are given an `Employees` table containing information about employees, their managers, and their salaries.

### Table: `Employees`

| Column        | Type    |
| ------------- | ------- |
| `employee_id` | int     |
| `name`        | varchar |
| `manager_id`  | int     |
| `salary`      | int     |

* `employee_id` is the primary key.
* `manager_id` contains the `employee_id` of the employee's manager.
* If an employee does not have a manager, `manager_id` is `NULL`.
* When a manager leaves the company, their row is **deleted** from the table.
* However, employees who reported to that manager still have the manager's old ID in their `manager_id`.

Find the IDs of employees who:

1. Have a salary **strictly less than `$30,000`**, and
2. Their manager has **left the company**.

Return the result ordered by `employee_id`.

---

## Solution 1: `NOT EXISTS`

```sql id="q8v3lm"
SELECT employee_id
FROM Employees e
WHERE salary < 30000
  AND manager_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM Employees m
      WHERE m.employee_id = e.manager_id
  )
ORDER BY employee_id;
```

### Explanation

The key idea is:

> An employee's manager has left the company if the manager's ID is stored in `manager_id`, but there is **no employee row with that ID** in the table.

For example:

| employee_id | name   | manager_id | salary |
| ----------: | ------ | ---------: | -----: |
|          11 | Joziah |          6 |  28485 |

Joziah's:

```text
manager_id = 6
```

But there is no:

```text
employee_id = 6
```

in the table.

Therefore, employee `6` must have left the company.

---

# Step 1: Find employees earning less than $30,000

We start with:

```sql id="y6k4pw"
WHERE salary < 30000
```

The word **strictly** means that an employee earning exactly `$30,000` should **not** be included.

For example:

| salary | Included? |
| -----: | --------- |
| 29,999 | Yes       |
| 30,000 | No        |
| 30,001 | No        |

So:

```sql id="d9m2xa"
salary < 30000
```

handles the salary requirement.

---

# Step 2: Make sure the employee actually has a manager

We also use:

```sql id="f4c7zn"
AND manager_id IS NOT NULL
```

Why?

If:

```text id="w8p2hs"
manager_id = NULL
```

then the employee does not have a manager.

They cannot have a manager who left the company because there is no manager associated with them in the first place.

Therefore, we explicitly exclude:

```text id="k3r7vb"
manager_id IS NULL
```

---

# Step 3: Check whether the manager still exists

This is the most important part:

```sql id="a5n8qx"
NOT EXISTS (
    SELECT 1
    FROM Employees m
    WHERE m.employee_id = e.manager_id
)
```

Let's break this down.

The outer table is:

```sql id="c7h1zm"
Employees e
```

Here, `e` represents the employee we're currently checking.

Suppose:

```text id="v4p9ks"
e.employee_id = 11
e.manager_id = 6
```

We then look for:

```sql id="r2w6jc"
m.employee_id = 6
```

inside the `Employees` table.

If we find a row with employee ID `6`, the manager is still in the company.

If we don't find one, the manager has left.

---

## What does `EXISTS` mean?

`EXISTS` asks:

> Does at least one matching row exist?

For example:

```sql id="h7q3lm"
EXISTS (
    SELECT 1
    FROM Employees m
    WHERE m.employee_id = e.manager_id
)
```

means:

> Does the employee's manager currently exist in the `Employees` table?

If yes:

```text id="c9w4xa"
EXISTS = TRUE
```

If no:

```text id="n2v7kd"
EXISTS = FALSE
```

We need the opposite:

```sql id="p6s1zr"
NOT EXISTS
```

because we are looking for managers who **do not exist**.

---

# Why `SELECT 1`?

Inside:

```sql id="x8m3qn"
EXISTS (
    SELECT 1
    FROM Employees m
    WHERE ...
)
```

the `1` is not important.

`EXISTS` only cares whether at least one row is found.

So these would all work:

```sql id="e4j7vc"
SELECT 1
```

or:

```sql id="a9f2wp"
SELECT *
```

or:

```sql id="r5k8yt"
SELECT employee_id
```

The conventional approach is:

```sql id="u3q6nb"
SELECT 1
```

because we're only asking:

> Does a matching row exist?

We don't actually need any column from that row.

---

# Step 4: Put the Conditions Together

Our complete `WHERE` clause is:

```sql id="w9c2ka"
WHERE salary < 30000
  AND manager_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM Employees m
      WHERE m.employee_id = e.manager_id
  )
```

Read it in plain English:

> Find employees whose salary is below $30,000, who have a manager ID, and for whom no employee with that manager ID currently exists.

That is exactly what the problem asks for.

---

# Example Walkthrough

Given:

| employee_id | name      | manager_id | salary |
| ----------: | --------- | ---------: | -----: |
|           3 | Mila      |          9 |  60301 |
|          12 | Antonella |       NULL |  31000 |
|          13 | Emery     |       NULL |  67084 |
|           1 | Kalel     |         11 |  21241 |
|           9 | Mikaela   |       NULL |  50937 |
|          11 | Joziah    |          6 |  28485 |

## Step 1: Find employees with salary < $30,000

The candidates are:

| employee_id | name   | manager_id | salary |
| ----------: | ------ | ---------: | -----: |
|           1 | Kalel  |         11 |  21241 |
|          11 | Joziah |          6 |  28485 |

---

## Step 2: Check Kalel's manager

Kalel has:

```text id="b4m7qc"
manager_id = 11
```

Does employee `11` exist?

Yes:

| employee_id | name   |
| ----------: | ------ |
|          11 | Joziah |

Therefore:

```text id="f8n3wd"
manager still exists
```

Kalel is **not** included.

---

## Step 3: Check Joziah's manager

Joziah has:

```text id="k5p2vx"
manager_id = 6
```

Does employee `6` exist?

No.

There is no row with:

```text id="m9q4rz"
employee_id = 6
```

Therefore:

```text id="s7t1yc"
manager has left
```

Joziah satisfies both conditions:

```text id="w2h6na"
salary < 30000
AND
manager does not exist
```

So we return:

```text id="j4k8vp"
11
```

---

# Solution 2: `LEFT JOIN`

The same logic can be expressed using a self `LEFT JOIN`.

```sql id="n6r2fx"
SELECT e.employee_id
FROM Employees e
LEFT JOIN Employees m
    ON e.manager_id = m.employee_id
WHERE e.salary < 30000
  AND e.manager_id IS NOT NULL
  AND m.employee_id IS NULL
ORDER BY e.employee_id;
```

### Explanation

This solution uses the `Employees` table twice:

```text id="q7v3lm"
e → employee
m → manager
```

This is a **self join** because we are joining the table to itself.

---

# Step 1: Join Employees to Their Managers

```sql id="z4c8kp"
LEFT JOIN Employees m
    ON e.manager_id = m.employee_id
```

The relationship is:

```text id="r1f6yx"
employee.manager_id
        ↓
manager.employee_id
```

For example:

```text id="p3w9qs"
Joziah:
manager_id = 6
```

We search for:

```text id="v8n2ka"
manager.employee_id = 6
```

But no such row exists.

---

# Step 2: Understand What `LEFT JOIN` Does

This is why `LEFT JOIN` is useful here.

A `LEFT JOIN` keeps **every employee from the left table**, even if their manager doesn't exist.

For Joziah:

| e.employee_id | e.name | e.manager_id | m.employee_id |
| ------------: | ------ | -----------: | ------------: |
|            11 | Joziah |            6 |          NULL |

Because manager `6` doesn't exist, all columns from the manager side (`m`) become `NULL`.

This gives us a way to identify employees whose managers have left.

---

# Step 3: Look for `NULL` Manager Matches

We use:

```sql id="c5h8zn"
AND m.employee_id IS NULL
```

This means:

> The join couldn't find a manager with the specified ID.

Therefore, the manager must have left the company.

This is a very common SQL pattern:

```text id="k7q2pd"
LEFT JOIN
    ↓
No matching row
    ↓
Joined columns become NULL
    ↓
WHERE joined_table.key IS NULL
    ↓
Find unmatched rows
```

---

# Why `LEFT JOIN` Instead of `INNER JOIN`?

An `INNER JOIN` would remove employees whose managers don't exist.

But those are exactly the employees we are trying to find!

For example:

```text id="d3m8vr"
Joziah → manager_id = 6
```

There is no manager `6`.

An `INNER JOIN` would discard Joziah.

A `LEFT JOIN` preserves Joziah and gives:

```text id="y6p1ks"
m.employee_id = NULL
```

which lets us identify him.

Therefore, `LEFT JOIN` is the appropriate join here.

---

# `NOT EXISTS` vs `LEFT JOIN`

Both solutions are correct.

### `NOT EXISTS`

```sql id="r8k4wp"
SELECT e.employee_id
FROM Employees e
WHERE e.salary < 30000
  AND e.manager_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM Employees m
      WHERE m.employee_id = e.manager_id
  )
ORDER BY e.employee_id;
```

Think:

> Find employees for whom **no manager row exists**.

### `LEFT JOIN`

```sql id="x3n7qc"
SELECT e.employee_id
FROM Employees e
LEFT JOIN Employees m
    ON e.manager_id = m.employee_id
WHERE e.salary < 30000
  AND e.manager_id IS NOT NULL
  AND m.employee_id IS NULL
ORDER BY e.employee_id;
```

Think:

> Join employees to their managers, then keep the ones where the manager side is `NULL`.

Both express the same idea.

---

# Why `manager_id IS NOT NULL` Matters

It's important not to confuse:

```text id="j5v9xk"
manager left the company
```

with:

```text id="p2c7rm"
employee never had a manager
```

If:

```text id="h8w4nz"
manager_id IS NULL
```

the employee simply doesn't have a manager.

We should not classify this as "manager left."

Therefore, we use:

```sql id="q6r1vy"
manager_id IS NOT NULL
```

before checking whether the manager exists.

---

# Important SQL Concept: `NULL`

Suppose an employee has:

```text id="s4m8kp"
manager_id = NULL
```

We should **not** write:

```sql id="w7n2fc"
manager_id = NULL
```

or:

```sql id="d9q5hx"
manager_id <> NULL
```

SQL uses special operators for `NULL`:

```sql id="a2k6vz"
IS NULL
```

and:

```sql id="f5r8ny"
IS NOT NULL
```

So:

```sql id="m3x7qp"
manager_id IS NOT NULL
```

is the correct way to check that an employee has a manager ID.

---

# Key Takeaway

The most important idea in this problem is:

> A manager who left the company has a `manager_id` that is still referenced by an employee, but that manager's `employee_id` no longer exists in the table.

You can detect this in two common ways.

### Using `NOT EXISTS`

```sql id="k8v2rm"
SELECT employee_id
FROM Employees e
WHERE salary < 30000
  AND manager_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM Employees m
      WHERE m.employee_id = e.manager_id
  )
ORDER BY employee_id;
```

### Using `LEFT JOIN`

```sql id="n4q7xc"
SELECT e.employee_id
FROM Employees e
LEFT JOIN Employees m
    ON e.manager_id = m.employee_id
WHERE e.salary < 30000
  AND e.manager_id IS NOT NULL
  AND m.employee_id IS NULL
ORDER BY e.employee_id;
```

### General pattern to remember

When a problem says:

> "Find rows whose referenced record no longer exists."

Think:

```text id="v6s3kp"
Option 1:
NOT EXISTS

Option 2:
LEFT JOIN + IS NULL
```

For this problem:

```text id="r8w2mn"
employee.manager_id
        ↓
Does this employee_id exist?
        ↓
NO
        ↓
Manager left
```

And don't forget the separate salary condition:

```text id="c5j9qa"
salary < 30000
```
