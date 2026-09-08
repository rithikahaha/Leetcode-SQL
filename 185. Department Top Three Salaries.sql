# 185. Department Top Three Salaries

> **Difficulty:** Hard

## Problem

We are given two tables:

* `Employee` — contains employee information, including salary and department.
* `Department` — contains department IDs and names.

A **high earner** is an employee whose salary is among the **top three unique salaries** in their department.

We need to return:

* `Department` — department name
* `Employee` — employee name
* `Salary` — employee salary

If multiple employees have the same salary, **all of them must be included**.

For example, if a department has these salaries:

```text id="9d2k4x"
90000
85000
85000
70000
60000
```

the top three **unique** salaries are:

```text id="0v8m1p"
90000
85000
70000
```

Therefore, all employees earning `90000`, `85000`, or `70000` are high earners.

### Table: `Employee`

| Column         | Type    | Description                 |
| -------------- | ------- | --------------------------- |
| `id`           | int     | Employee ID; primary key    |
| `name`         | varchar | Employee name               |
| `salary`       | int     | Employee salary             |
| `departmentId` | int     | ID of employee's department |

### Table: `Department`

| Column | Type    | Description                |
| ------ | ------- | -------------------------- |
| `id`   | int     | Department ID; primary key |
| `name` | varchar | Department name            |

---

# Solution 1: `DENSE_RANK()` — Recommended

```sql id="r7k2m9"
SELECT
    d.name AS Department,
    e.name AS Employee,
    e.salary AS Salary
FROM (
    SELECT
        e.*,
        DENSE_RANK() OVER (
            PARTITION BY departmentId
            ORDER BY salary DESC
        ) AS salary_rank
    FROM Employee e
) e
JOIN Department d
    ON e.departmentId = d.id
WHERE e.salary_rank <= 3;
```

### Explanation

This problem becomes much easier once we recognize what **"top three unique salaries"** means.

We need to rank salaries **within each department**, while giving the same rank to employees who have the same salary.

That is exactly what `DENSE_RANK()` is designed for.

---

# Step 1: Rank Employees Within Each Department

```sql id="n4x8c2"
DENSE_RANK() OVER (
    PARTITION BY departmentId
    ORDER BY salary DESC
)
```

There are two important pieces here:

```sql id="7c2p6v"
PARTITION BY departmentId
```

and:

```sql id="m8q1z5"
ORDER BY salary DESC
```

---

## What Does `PARTITION BY` Do?

```sql id="h3v9k1"
PARTITION BY departmentId
```

means:

> Calculate the ranking separately for each department.

For example, IT employees are ranked against other IT employees.

Sales employees are ranked against other Sales employees.

The ranking does **not** compare an IT employee's salary against a Sales employee's salary.

Conceptually:

```text id="s5n2r8"
IT
├── Max
├── Joe
├── Randy
└── Will

Sales
├── Henry
└── Sam
```

Each department gets its own ranking.

---

# Step 2: Sort Salaries from Highest to Lowest

```sql id="6m1q9x"
ORDER BY salary DESC
```

`DESC` means descending order.

So within IT:

```text id="0f7q3k"
90000
85000
85000
70000
```

becomes:

```text id="t8w4m2"
Max   → 90000
Joe   → 85000
Randy → 85000
Will  → 70000
```

---

# Step 3: Why `DENSE_RANK()`?

This is the **most important concept in this problem**.

`DENSE_RANK()` gives the same rank to equal values and does not skip the next rank.

For IT:

| Employee | Salary | DENSE_RANK |
| -------- | -----: | ---------: |
| Max      |  90000 |          1 |
| Joe      |  85000 |          2 |
| Randy    |  85000 |          2 |
| Will     |  70000 |          3 |

Notice what happens with Joe and Randy.

Both earn:

```text id="5c1m8p"
85000
```

so both receive:

```text id="7x4n2q"
rank = 2
```

Then Will receives:

```text id="3v8k6m"
rank = 3
```

There is no gap.

---

# Why Not `ROW_NUMBER()`?

This is a very common interview question.

If we used:

```sql id="p9r3w6"
ROW_NUMBER() OVER (
    PARTITION BY departmentId
    ORDER BY salary DESC
)
```

the IT employees would receive:

| Employee | Salary | ROW_NUMBER |
| -------- | -----: | ---------: |
| Max      |  90000 |          1 |
| Joe      |  85000 |          2 |
| Randy    |  85000 |          3 |
| Will     |  70000 |          4 |

If we then wrote:

```sql id="c6x1q8"
WHERE row_number <= 3
```

we would get:

```text id="y4m7z2"
Max
Joe
Randy
```

but **Will would incorrectly be excluded**.

The problem says **top three unique salaries**, not top three employees.

Therefore, `ROW_NUMBER()` is wrong here.

---

# Why Not `RANK()`?

`RANK()` gives the same rank to ties, but it **skips ranks after a tie**.

For IT:

```text id="n7p2k5"
90000 → rank 1
85000 → rank 2
85000 → rank 2
70000 → rank 4
```

Notice:

```text id="z3q8m1"
1, 2, 2, 4
```

There is no rank `3`.

If we use:

```sql id="h5v9c4"
WHERE rank <= 3
```

Will would be excluded.

But Will earns the **third-highest unique salary**.

So `RANK()` is also wrong for this problem.

---

# `DENSE_RANK()` vs `RANK()` vs `ROW_NUMBER()`

This distinction is extremely important.

Suppose salaries are:

```text id="7k2m5q"
100000
90000
90000
80000
```

### `ROW_NUMBER()`

```text id="1r8x3c"
100000 → 1
90000  → 2
90000  → 3
80000  → 4
```

Every row gets a different number.

### `RANK()`

```text id="6p4v9m"
100000 → 1
90000  → 2
90000  → 2
80000  → 4
```

Ties create gaps.

### `DENSE_RANK()`

```text id="2x7n5k"
100000 → 1
90000  → 2
90000  → 2
80000  → 3
```

Ties do not create gaps.

Therefore:

> **When a problem asks for the top N unique values and all ties should be included, think `DENSE_RANK()`.**

---

# Step 4: Keep the Top Three Ranks

After calculating:

```sql id="v6q1m8"
DENSE_RANK() OVER (...)
```

we have a `salary_rank` column.

Then:

```sql id="f8z3k5"
WHERE e.salary_rank <= 3
```

keeps:

```text id="h2m7q4"
rank 1
rank 2
rank 3
```

and removes everything below the third unique salary.

For IT:

| Employee | Salary | Rank | Keep? |
| -------- | -----: | ---: | ----- |
| Max      |  90000 |    1 | ✅     |
| Joe      |  85000 |    2 | ✅     |
| Randy    |  85000 |    2 | ✅     |
| Will     |  70000 |    3 | ✅     |

For Sales:

| Employee | Salary | Rank | Keep? |
| -------- | -----: | ---: | ----- |
| Henry    |  80000 |    1 | ✅     |
| Sam      |  60000 |    2 | ✅     |

Sales has only two unique salaries, so there is simply no rank 3. That's completely fine.

---

# Step 5: Why Do We Need the `Department` Table?

The `Employee` table contains:

```text id="q3x8m6"
departmentId
```

but the required output wants:

```text id="w7k2p4"
Department
```

meaning the **department name**, not the ID.

So we join:

```sql id="m9c5x1"
JOIN Department d
    ON e.departmentId = d.id
```

For example:

```text id="b4q7v9"
Employee:
departmentId = 1
```

matches:

```text id="x8m3k5"
Department:
id = 1
name = IT
```

Now we can output:

```sql id="j6p1r8"
d.name AS Department
```

---

# Step 6: Why Is the Ranking Done Before the Join?

The ranking only needs information from `Employee`:

```sql id="a8v4n2"
departmentId
salary
```

So we first calculate the ranking:

```sql id="g5q9m1"
SELECT
    e.*,
    DENSE_RANK() OVER (
        PARTITION BY departmentId
        ORDER BY salary DESC
    ) AS salary_rank
FROM Employee e
```

Then we join to `Department` to get the department name.

This keeps the ranking logic simple.

---

# Solution 2: Correlated Subquery

The problem can also be solved without window functions.

```sql id="c7m4x9"
SELECT
    d.name AS Department,
    e.name AS Employee,
    e.salary AS Salary
FROM Employee e
JOIN Department d
    ON e.departmentId = d.id
WHERE 3 > (
    SELECT COUNT(DISTINCT e2.salary)
    FROM Employee e2
    WHERE e2.departmentId = e.departmentId
      AND e2.salary > e.salary
);
```

### Explanation

This solution uses a clever way of thinking about ranking.

For every employee, we ask:

> How many **unique salaries** in this employee's department are higher than this employee's salary?

If fewer than 3 unique salaries are higher, then the employee must be in the top 3 unique salaries.

---

## Example

Suppose IT salaries are:

```text id="n8c2v5"
90000
85000
85000
70000
60000
```

Consider Will with salary `70000`.

The salaries higher than `70000` are:

```text id="q4m7x1"
90000
85000
85000
```

But we use:

```sql id="v6p3k9"
COUNT(DISTINCT e2.salary)
```

so we count:

```text id="z1r8m4"
90000
85000
```

That's only **2 unique salaries** above Will.

Therefore, Will is in the top 3.

---

## Why `COUNT(DISTINCT e2.salary)`?

This is essential.

Suppose:

```text id="y7c2m9"
Joe   → 85000
Randy → 85000
```

They have the same salary.

We don't want to count that salary twice because the problem asks for **unique salaries**.

So:

```sql id="j5q8v3"
COUNT(DISTINCT e2.salary)
```

counts:

```text id="w4n6p2"
85000
```

only once.

---

## Why `e2.departmentId = e.departmentId`?

We only care about salaries **within the same department**.

```sql id="s9x1k7"
WHERE e2.departmentId = e.departmentId
```

prevents salaries from other departments from affecting the employee's rank.

Without this condition, an employee in IT could incorrectly be ranked against Sales employees.

---

## Why `e2.salary > e.salary`?

We want to find salaries that are **strictly higher** than the current employee's salary.

For an employee earning `70000`:

```sql id="r6m3q8"
e2.salary > 70000
```

finds:

```text id="h1v7c4"
90000
85000
```

The number of unique salaries above the employee determines their position.

---

## Why `3 > COUNT(...)`?

The condition:

```sql id="k8p2m5"
3 > COUNT(DISTINCT e2.salary)
```

is equivalent to:

```text id="j4q9v6"
COUNT(DISTINCT higher salaries) < 3
```

If there are:

```text id="z6m1x8"
0 unique salaries higher → rank 1
1 unique salary higher  → rank 2
2 unique salaries higher → rank 3
3 unique salaries higher → rank 4
```

Therefore, we keep employees where the count is less than `3`.

---

# Comparing the Two Solutions

### Window function

```sql id="f2k7m9"
DENSE_RANK() OVER (
    PARTITION BY departmentId
    ORDER BY salary DESC
)
```

This directly says:

> Rank salaries within each department.

### Correlated subquery

```sql id="p8x4c1"
COUNT(DISTINCT e2.salary)
```

says:

> Count how many unique salaries are higher than this employee's salary.

Both approaches correctly handle duplicate salaries.

---

# Which Solution Should You Remember?

The **`DENSE_RANK()` solution is the best one to remember**.

The problem's phrase:

> **top three unique salaries**

is almost a direct hint toward:

```sql id="m3v8q5"
DENSE_RANK()
```

The general pattern is:

```sql id="x7k2p9"
DENSE_RANK() OVER (
    PARTITION BY group_column
    ORDER BY value_column DESC
)
```

then:

```sql id="j4m6c8"
WHERE rank <= N
```

This works for questions such as:

* Top 3 salaries per department
* Top 5 products per category
* Top 3 scores per class
* Top N unique values within each group

---

# Important Concept: "Top N" vs "Top N Unique"

This is the biggest trap in this problem.

Suppose a department has:

```text id="c8m2v6"
100000
90000
90000
80000
```

### Top 3 employees

Would be:

```text id="r5x1q7"
100000
90000
90000
```

### Top 3 unique salaries

Would be:

```text id="n7k4p2"
100000
90000
80000
```

The problem specifically asks for the second one.

That's why `DENSE_RANK()` is appropriate.

---

# Important Concept: Why `DENSE_RANK()` Handles Ties Correctly

Imagine:

```text id="m1q8v4"
Salary
100000
90000
90000
80000
70000
```

`DENSE_RANK()` produces:

```text id="k6x2p9"
100000 → 1
90000  → 2
90000  → 2
80000  → 3
70000  → 4
```

So:

```sql id="q3v7m1"
WHERE salary_rank <= 3
```

returns:

```text id="r9c4x6"
100000
90000
90000
80000
```

Exactly what the problem asks for.

---

# Important Concept: `PARTITION BY`

Remember that:

```sql id="w8m2k5"
PARTITION BY departmentId
```

does **not** combine rows like `GROUP BY`.

Instead, it creates independent windows.

For example:

```text id="j4q9v7"
IT:
90000 → rank 1
85000 → rank 2
70000 → rank 3

Sales:
80000 → rank 1
60000 → rank 2
```

The ranking starts over for every department.

This is one of the most important uses of `PARTITION BY`.

---

# Key Takeaway

The main pattern to remember from this problem is:

```sql id="p6x3m8"
DENSE_RANK() OVER (
    PARTITION BY departmentId
    ORDER BY salary DESC
)
```

followed by:

```sql id="c9v4q1"
WHERE salary_rank <= 3
```

The reasoning is:

```text id="m7k2x5"
Employees
    ↓
Separate by department
    ↓
PARTITION BY departmentId
    ↓
Sort salaries highest → lowest
    ↓
DENSE_RANK()
    ↓
Same salary = same rank
    ↓
No gaps between ranks
    ↓
Keep rank <= 3
    ↓
JOIN Department for department name
```

### Ranking functions to remember

| Function       | Ties              | Gaps after ties? | Best use                  |
| -------------- | ----------------- | ---------------- | ------------------------- |
| `ROW_NUMBER()` | Different numbers | N/A              | Top N individual rows     |
| `RANK()`       | Same rank         | Yes              | Competition-style ranking |
| `DENSE_RANK()` | Same rank         | **No**           | **Top N unique values**   |

The key rule is:

> **If a problem says "top N unique salaries/values" and everyone tied at the cutoff should be included, think `DENSE_RANK()`.**
