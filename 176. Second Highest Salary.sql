# 176. Second Highest Salary

> **Difficulty:** Medium

## Problem

We need to find the **second highest distinct salary** from the `Employee` table.

If there is no second highest salary, the result should be `NULL`.

### Table: `Employee`

| Column Name | Type | Description       |
| ----------- | ---- | ----------------- |
| `id`        | int  | Primary key       |
| `salary`    | int  | Employee's salary |

### Example

**Input:**

| id | salary |
| -: | -----: |
|  1 |    100 |
|  2 |    200 |
|  3 |    300 |

**Output:**

| SecondHighestSalary |
| ------------------: |
|                 200 |

If the table contains only one distinct salary:

| id | salary |
|---:|
| 1 | 100 |

The output should be:

| SecondHighestSalary |
| ------------------: |
|                NULL |

---

# Solution 1: `MAX()` + Subquery

```sql
SELECT MAX(salary) AS SecondHighestSalary
FROM Employee
WHERE salary < (
    SELECT MAX(salary)
    FROM Employee
);
```

### Explanation

The key idea is:

> Find the highest salary first, then find the highest salary that is **less than** it.

### Step 1: Find the highest salary

```sql
SELECT MAX(salary)
FROM Employee;
```

For:

| salary |
| -----: |
|    100 |
|    200 |
|    300 |

This returns:

```text
300
```

---

### Step 2: Keep salaries below the highest salary

```sql
WHERE salary < (
    SELECT MAX(salary)
    FROM Employee
)
```

This effectively becomes:

```sql
WHERE salary < 300
```

So the remaining salaries are:

```text
100
200
```

---

### Step 3: Find the maximum of those salaries

```sql
SELECT MAX(salary)
```

The maximum of `100` and `200` is:

```text
200
```

Therefore:

```text
SecondHighestSalary = 200
```

---

### Why does this return `NULL` when there is no second highest salary?

Suppose the table contains:

| salary |
| -----: |
|    100 |

The subquery returns:

```text
100
```

So the outer query becomes:

```sql
WHERE salary < 100
```

There are no rows satisfying that condition.

Then:

```sql
MAX(salary)
```

over an empty result returns:

```text
NULL
```

This is exactly what the problem asks for.

---

# Solution 2: `DISTINCT` + `ORDER BY` + `LIMIT`

Another common solution is:

```sql
SELECT (
    SELECT DISTINCT salary
    FROM Employee
    ORDER BY salary DESC
    LIMIT 1 OFFSET 1
) AS SecondHighestSalary;
```

### Explanation

Here we first sort the **distinct** salaries from highest to lowest.

For example:

| salary |
| -----: |
|    100 |
|    200 |
|    200 |
|    300 |

Using:

```sql
SELECT DISTINCT salary
FROM Employee
ORDER BY salary DESC
```

gives:

| salary |
| -----: |
|    300 |
|    200 |
|    100 |

Notice that `200` appears only once because of:

```sql
DISTINCT
```

This is important because the problem asks for the **second highest distinct salary**.

---

### What does `OFFSET 1` mean?

```sql
LIMIT 1 OFFSET 1
```

means:

* `OFFSET 1` → skip the first row
* `LIMIT 1` → return the next one row

So:

| salary |
| -----: |
|    300 |
|    200 |
|    100 |

After skipping `300`, we take `200`.

Therefore:

```text
200
```

---

### Why use a subquery here?

If we simply wrote:

```sql
SELECT DISTINCT salary
FROM Employee
ORDER BY salary DESC
LIMIT 1 OFFSET 1;
```

the query returns **no row** if there isn't a second salary.

But the problem specifically requires:

```text
NULL
```

The outer query:

```sql
SELECT (
    ...
) AS SecondHighestSalary;
```

turns the missing result into a single row containing `NULL`.

So with only:

| salary |
| -----: |
|    100 |

the inner query finds nothing, and the final result is:

| SecondHighestSalary |
| ------------------: |
|                NULL |

---

# Solution 3: `DENSE_RANK()`

We can also solve this using a window function:

```sql
SELECT MAX(salary) AS SecondHighestSalary
FROM (
    SELECT
        salary,
        DENSE_RANK() OVER (ORDER BY salary DESC) AS salary_rank
    FROM Employee
) e
WHERE salary_rank = 2;
```

### Explanation

`DENSE_RANK()` assigns a ranking to salaries.

For example:

| salary | salary_rank |
| -----: | ----------: |
|    300 |           1 |
|    200 |           2 |
|    100 |           3 |

So we simply select:

```sql
WHERE salary_rank = 2
```

to get the second highest salary.

---

## Why `DENSE_RANK()` instead of `ROW_NUMBER()`?

This problem specifically says:

> **second highest distinct salary**

Suppose the salaries are:

| salary |
| -----: |
|    300 |
|    300 |
|    200 |
|    100 |

With `DENSE_RANK()`:

| salary | rank |
| -----: | ---: |
|    300 |    1 |
|    300 |    1 |
|    200 |    2 |
|    100 |    3 |

So `200` is correctly identified as the second highest **distinct** salary.

With `ROW_NUMBER()`:

| salary | row_number |
| -----: | ---------: |
|    300 |          1 |
|    300 |          2 |
|    200 |          3 |
|    100 |          4 |

That would incorrectly treat the second `300` as the second highest salary.

Therefore, for ranking **distinct values**, `DENSE_RANK()` is usually the appropriate window function.

---

# Important SQL Concepts

## 1. Why do we need `DISTINCT`?

The word **distinct** in the problem is important.

Suppose:

```text
300
300
200
100
```

The second highest salary is:

```text
200
```

not:

```text
300
```

So when using `ORDER BY` + `LIMIT`, we need:

```sql
SELECT DISTINCT salary
```

to remove duplicate salary values before finding the second one.

---

## 2. Why use `MAX()` instead of `ORDER BY` in Solution 1?

This:

```sql
SELECT MAX(salary)
FROM Employee
WHERE salary < (
    SELECT MAX(salary)
    FROM Employee
);
```

is essentially saying:

> "Give me the largest salary that isn't the largest salary."

That naturally produces the second highest **distinct** salary.

It also has a useful property: `MAX()` returns `NULL` when there are no qualifying rows, which automatically handles the one-salary case.

---

## 3. Why not simply use `ORDER BY salary DESC LIMIT 1, 1`?

You might see:

```sql
SELECT salary
FROM Employee
ORDER BY salary DESC
LIMIT 1, 1;
```

The problem is that this doesn't handle duplicate salaries correctly.

For:

| salary |
| -----: |
|    300 |
|    300 |
|    200 |

it would skip the first `300` and return the second `300`.

But the problem asks for the second **distinct** salary.

Therefore, if using `ORDER BY`, we need:

```sql
SELECT DISTINCT salary
FROM Employee
ORDER BY salary DESC
LIMIT 1 OFFSET 1;
```

---

# Key Takeaway

There are several ways to think about **"second highest distinct value"** problems:

### Pattern 1 — `MAX()` + subquery

```sql
SELECT MAX(column)
FROM table
WHERE column < (
    SELECT MAX(column)
    FROM table
);
```

Think:

> **Find the largest value below the overall maximum.**

### Pattern 2 — `DISTINCT` + sorting

```sql
SELECT (
    SELECT DISTINCT column
    FROM table
    ORDER BY column DESC
    LIMIT 1 OFFSET 1
);
```

Think:

> **Remove duplicates → sort descending → skip the highest → take the next one.**

### Pattern 3 — `DENSE_RANK()`

```sql
DENSE_RANK() OVER (ORDER BY column DESC)
```

Think:

> **Rank unique values, and select rank 2.**

For this particular problem, **Solution 1 (`MAX()` + subquery)** is arguably the cleanest because it naturally returns `NULL` when a second distinct salary doesn't exist.
