# 1731. The Number of Employees Which Report to Each Employee

> **Difficulty:** Easy

## Problem

You are given an `Employees` table containing information about employees and the employee they report to.

### Table: `Employees`

| Column        | Type    |
| ------------- | ------- |
| `employee_id` | int     |
| `name`        | varchar |
| `reports_to`  | int     |
| `age`         | int     |

* `employee_id` is unique for each employee.
* `reports_to` contains the `employee_id` of the employee's manager.
* If an employee does not report to anyone, `reports_to` is `NULL`.

For this problem, an employee is considered a **manager** if at least one other employee reports directly to them.

Return:

* The manager's `employee_id`
* The manager's `name`
* The number of employees who report **directly** to them
* The average age of their direct reports, rounded to the nearest integer

Order the result by `employee_id`.

---

## Solution: Self Join + `GROUP BY`

```sql
SELECT m.employee_id,
       m.name,
       COUNT(e.employee_id) AS reports_count,
       ROUND(AVG(e.age)) AS average_age
FROM Employees m
JOIN Employees e
    ON m.employee_id = e.reports_to
GROUP BY m.employee_id, m.name
ORDER BY m.employee_id;
```

### Explanation

The important thing to recognize is that the table contains **both employees and their managers**.

For example:

| employee_id | name  | reports_to |
| ----------- | ----- | ---------- |
| 9           | Hercy | NULL       |
| 6           | Alice | 9          |
| 4           | Bob   | 9          |

Alice and Bob both have:

```text
reports_to = 9
```

which means employee `9` is their manager.

Therefore, we need to match the `employee_id` of one row with the `reports_to` of another row.

This is called a **self join** because we join the `Employees` table to itself.

---

## Step 1: Give the table two aliases

```sql
FROM Employees m
JOIN Employees e
```

We are using the same table twice, but each copy has a different purpose:

* `m` → represents the **manager**
* `e` → represents the **employee/report**

So:

```text
Employees m
     ↓
manager

Employees e
     ↓
employee reporting to that manager
```

The aliases make it possible to distinguish between the two copies of the table.

---

## Step 2: Match employees with their managers

```sql
ON m.employee_id = e.reports_to
```

This is the most important part of the query.

Remember:

```text
e.reports_to
```

contains the ID of the manager that employee `e` reports to.

So if:

```text
e.employee_id = 6
e.reports_to = 9
```

then we look for:

```text
m.employee_id = 9
```

The join condition:

```sql
m.employee_id = e.reports_to
```

connects Alice to Hercy and Bob to Hercy.

The resulting joined data would conceptually look like:

| Manager ID | Manager | Employee | Employee Age |
| ---------: | ------- | -------- | -----------: |
|          9 | Hercy   | Alice    |           41 |
|          9 | Hercy   | Bob      |           36 |

Now we have exactly the information needed to calculate the manager's report count and average report age.

---

## Step 3: Count the direct reports

```sql
COUNT(e.employee_id) AS reports_count
```

After the self join, each matching employee represents **one direct report**.

For Hercy:

```text
Alice → reports to Hercy
Bob   → reports to Hercy
```

Therefore:

```sql
COUNT(e.employee_id)
```

returns:

```text
2
```

### Why `COUNT(e.employee_id)`?

We specifically want to count the employee rows that matched the manager.

Since `e.employee_id` is non-NULL for every employee, each matching row contributes `1` to the count.

We could also use:

```sql
COUNT(*)
```

here because we are using an `INNER JOIN`, so every resulting row represents a valid employee-manager relationship.

Using `COUNT(e.employee_id)` makes the intention particularly clear: **count the employees reporting to the manager**.

---

## Step 4: Calculate the average age

```sql
AVG(e.age) AS average_age
```

We use the `age` of the **reports**, not the manager.

For Hercy:

```text
Alice → 41
Bob   → 36
```

Therefore:

```text
(41 + 36) / 2 = 38.5
```

---

## Step 5: Round the average

The problem asks for the average age rounded to the nearest integer.

So we use:

```sql
ROUND(AVG(e.age)) AS average_age
```

For example:

```text
38.5 → 39
```

`ROUND()` rounds a numeric value to the nearest integer when no number of decimal places is specified.

---

## Step 6: Group by manager

```sql
GROUP BY m.employee_id, m.name
```

We need one output row for each manager.

Without `GROUP BY`, all of the employee-manager matches would be treated as one large group.

By grouping by:

```sql
m.employee_id, m.name
```

we calculate:

* `COUNT()` for each manager
* `AVG()` for each manager

For example:

```text
Hercy
 ├── Alice (41)
 └── Bob   (36)
```

becomes one group.

Then:

```sql
COUNT(e.employee_id)
```

calculates Hercy's report count, and:

```sql
AVG(e.age)
```

calculates the average age of Hercy's reports.

---

## Why do we group by both `employee_id` and `name`?

We select:

```sql
m.employee_id,
m.name
```

along with aggregate functions:

```sql
COUNT(...)
AVG(...)
```

Therefore, the non-aggregated columns need to be included in the `GROUP BY`.

So we use:

```sql
GROUP BY m.employee_id, m.name
```

This gives us one row per manager.

---

## Why does this automatically return only managers?

The query uses:

```sql
JOIN Employees e
    ON m.employee_id = e.reports_to
```

An `INNER JOIN` only keeps rows where a match exists.

Therefore, an employee will appear as `m` only if at least one other employee has:

```text
reports_to = m.employee_id
```

In other words:

> If someone has at least one direct report, they appear in the result.

That is exactly the definition of a manager in this problem.

Employees with no direct reports have no matching `e` row, so they are automatically excluded.

---

## Why is this a Self Join?

A **self join** means joining a table to itself.

Here, the same `Employees` table contains two related types of information:

```text
employee_id
    ↓
identifies an employee

reports_to
    ↓
identifies that employee's manager
```

We need to connect those two columns.

So:

```sql
Employees m
JOIN Employees e
```

allows us to compare:

```sql
m.employee_id
```

with:

```sql
e.reports_to
```

This is a very common SQL pattern for hierarchical data such as:

* Employees → Managers
* Employees → Supervisors
* Employees → Department heads
* Categories → Parent categories
* Employees → Mentors

---

## Visualizing the Join

Suppose the table contains:

| employee_id | name    | reports_to | age |
| ----------: | ------- | ---------: | --: |
|           1 | Michael |       NULL |  45 |
|           2 | Alice   |          1 |  38 |
|           3 | Bob     |          1 |  42 |
|           4 | Charlie |          2 |  34 |
|           5 | David   |          2 |  40 |
|           6 | Eve     |          3 |  37 |

The self join:

```sql
ON m.employee_id = e.reports_to
```

creates relationships like:

```text
Michael (1)
├── Alice (2)
└── Bob (3)

Alice (2)
├── Charlie (4)
└── David (5)

Bob (3)
└── Eve (6)
```

Therefore:

### Michael

```text
Direct reports:
Alice → 38
Bob   → 42

Count = 2
Average = (38 + 42) / 2 = 40
```

### Alice

```text
Direct reports:
Charlie → 34
David   → 40

Count = 2
Average = (34 + 40) / 2 = 37
```

### Bob

```text
Direct report:
Eve → 37

Count = 1
Average = 37
```

So the result is:

| employee_id | name    | reports_count | average_age |
| ----------: | ------- | ------------: | ----------: |
|           1 | Michael |             2 |          40 |
|           2 | Alice   |             2 |          37 |
|           3 | Bob     |             1 |          37 |

---

## Important: "Directly" Reporting

The problem specifically asks for employees who report **directly** to each manager.

This means we only use:

```sql
e.reports_to = m.employee_id
```

For example:

```text
Michael
└── Alice
    └── Charlie
```

Charlie ultimately works under Michael, but Charlie does **not** report directly to Michael.

Charlie has:

```text
reports_to = Alice
```

not:

```text
reports_to = Michael
```

Therefore:

* Michael's direct report → Alice
* Alice's direct report → Charlie
* Charlie is **not** counted as Michael's direct report

The self join handles this automatically because it only matches the immediate `reports_to` value.

---

## Why `JOIN` instead of `LEFT JOIN`?

We could technically write:

```sql
FROM Employees m
LEFT JOIN Employees e
    ON m.employee_id = e.reports_to
```

but then employees who have no reports would also appear.

The problem only asks for **managers**, meaning employees with at least one report.

Using:

```sql
JOIN
```

(`INNER JOIN`) automatically removes employees who have no matching reports.

So `INNER JOIN` is the natural choice here.

---

## Complete Query Breakdown

```sql
SELECT m.employee_id,
       m.name,
       COUNT(e.employee_id) AS reports_count,
       ROUND(AVG(e.age)) AS average_age
FROM Employees m
JOIN Employees e
    ON m.employee_id = e.reports_to
GROUP BY m.employee_id, m.name
ORDER BY m.employee_id;
```

Think about the query in this order:

### 1. Find manager-report relationships

```sql
JOIN Employees e
    ON m.employee_id = e.reports_to
```

### 2. Group reports by manager

```sql
GROUP BY m.employee_id, m.name
```

### 3. Count the reports

```sql
COUNT(e.employee_id)
```

### 4. Calculate their average age

```sql
AVG(e.age)
```

### 5. Round the average

```sql
ROUND(AVG(e.age))
```

### 6. Sort by employee ID

```sql
ORDER BY m.employee_id
```

---

## Key Takeaway

When a table contains a column that references another row in the **same table**, think about a **self join**.

Here:

```text
employee_id ←→ reports_to
```

The pattern is:

```sql
SELECT manager.employee_id,
       manager.name,
       COUNT(employee.employee_id),
       AVG(employee.age)
FROM Employees manager
JOIN Employees employee
    ON manager.employee_id = employee.reports_to
GROUP BY manager.employee_id, manager.name;
```

The key idea is:

> `reports_to` tells us **who the employee reports to**, so we match it with another row's `employee_id` to find the manager.

Then:

```text
GROUP BY manager
        ↓
COUNT → number of direct reports
        ↓
AVG   → average age of direct reports
        ↓
ROUND → nearest integer
```
