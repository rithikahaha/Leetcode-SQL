# 1204. Last Person to Fit in the Bus

> **Difficulty:** Medium

## Problem

You are given a `Queue` table containing information about people waiting to board a bus.

### Table: `Queue`

| Column        | Type    |
| ------------- | ------- |
| `person_id`   | int     |
| `person_name` | varchar |
| `weight`      | int     |
| `turn`        | int     |

* `person_id` is unique.
* `turn` determines the boarding order.
* `turn = 1` → first person to board.
* `turn = n` → last person in the queue.
* `weight` is the person's weight in kilograms.
* The bus has a maximum weight capacity of **1000 kg**.
* Only one person can board at each turn.
* The first person is guaranteed to fit.

Find the **last person who can board without the total weight exceeding 1000 kg**.

---

## Solution: Window Function with `SUM()`

```sql id="v8k2qm"
SELECT person_name
FROM (
    SELECT person_name,
           weight,
           turn,
           SUM(weight) OVER (ORDER BY turn) AS total_weight
    FROM Queue
) q
WHERE total_weight <= 1000
ORDER BY turn DESC
LIMIT 1;
```

### Explanation

The key idea is:

> We need to calculate the **running total of weight** in boarding order, then find the last person whose running total is still at most `1000`.

For example:

```text id="p6x3dr"
Turn 1 → 250 kg → total = 250
Turn 2 → 350 kg → total = 600
Turn 3 → 400 kg → total = 1000
Turn 4 → 200 kg → total = 1200
```

The last person who fits is the person at turn `3`.

---

## Step 1: Understand the Importance of `turn`

The rows in the table are not necessarily stored in boarding order.

For example:

| person_id | person_name | weight | turn |
| --------: | ----------- | -----: | ---: |
|         5 | Alice       |    250 |    1 |
|         4 | Bob         |    175 |    5 |
|         3 | Alex        |    350 |    2 |
|         6 | John Cena   |    400 |    3 |
|         1 | Winston     |    500 |    6 |
|         2 | Marie       |    200 |    4 |

The actual boarding order is:

```text id="z9w4pq"
turn 1 → Alice
turn 2 → Alex
turn 3 → John Cena
turn 4 → Marie
turn 5 → Bob
turn 6 → Winston
```

Therefore, whenever we calculate the cumulative weight, we must use:

```sql id="n4h7vs"
ORDER BY turn
```

---

# Step 2: Calculate the Running Total

We use:

```sql id="f6q8rx"
SUM(weight) OVER (ORDER BY turn)
```

This is a **window function**.

Unlike a regular:

```sql id="j8r2kp"
SUM(weight)
```

which would calculate one total for the entire group, the window version calculates a value for **each row** while keeping all the rows.

---

## What does `SUM(weight) OVER (ORDER BY turn)` mean?

Break it into two parts.

### `SUM(weight)`

```sql id="k2w7mc"
SUM(weight)
```

means:

> Add the weights together.

### `OVER (ORDER BY turn)`

```sql id="a5q9fd"
OVER (ORDER BY turn)
```

means:

> Do the calculation in boarding order and include the current row and all previous rows.

Together:

```sql id="c3m8vz"
SUM(weight) OVER (ORDER BY turn)
```

means:

> Calculate the cumulative/running weight as people board according to `turn`.

---

## Step 3: See What the Window Function Produces

For the example:

| turn | person_name | weight |
| ---: | ----------- | -----: |
|    1 | Alice       |    250 |
|    2 | Alex        |    350 |
|    3 | John Cena   |    400 |
|    4 | Marie       |    200 |
|    5 | Bob         |    175 |
|    6 | Winston     |    500 |

After:

```sql id="r6t1yk"
SUM(weight) OVER (ORDER BY turn)
```

we get:

| turn | person_name | weight | total_weight |
| ---: | ----------- | -----: | -----------: |
|    1 | Alice       |    250 |          250 |
|    2 | Alex        |    350 |          600 |
|    3 | John Cena   |    400 |         1000 |
|    4 | Marie       |    200 |         1200 |
|    5 | Bob         |    175 |         1375 |
|    6 | Winston     |    500 |         1875 |

This is exactly what we need.

---

# Step 4: Keep People Who Fit

Now we need to keep only people whose cumulative weight doesn't exceed the bus capacity.

The limit is:

```text id="h4c7n2"
1000 kg
```

So we use:

```sql id="v1q6sx"
WHERE total_weight <= 1000
```

This leaves:

| turn | person_name | total_weight |
| ---: | ----------- | -----------: |
|    1 | Alice       |          250 |
|    2 | Alex        |          600 |
|    3 | John Cena   |         1000 |

Marie and everyone after her are excluded because their cumulative weight exceeds `1000`.

---

# Step 5: Find the Last Person

We now have all people who can fit.

But we want the **last** one.

We can sort them by `turn` in descending order:

```sql id="e9s5cw"
ORDER BY turn DESC
```

This gives:

| turn | person_name |
| ---: | ----------- |
|    3 | John Cena   |
|    2 | Alex        |
|    1 | Alice       |

Then:

```sql id="q3f7za"
LIMIT 1
```

takes the first row from that result.

Therefore:

```text id="m5v2kn"
John Cena
```

is the answer.

---

# Why Do We Need a Subquery?

Notice that the query is:

```sql id="a7k3pf"
SELECT person_name
FROM (
    SELECT person_name,
           weight,
           turn,
           SUM(weight) OVER (ORDER BY turn) AS total_weight
    FROM Queue
) q
WHERE total_weight <= 1000
ORDER BY turn DESC
LIMIT 1;
```

The inner query creates:

```sql id="w8r1cx"
total_weight
```

for every person.

The outer query then filters using:

```sql id="d2x6hs"
WHERE total_weight <= 1000
```

We need the subquery because the window-function result is calculated as part of the `SELECT`.

The outer query can then treat `total_weight` like a normal column and filter it.

Think of it as two stages:

```text id="f7q2nm"
INNER QUERY
    ↓
Calculate running total
    ↓
OUTER QUERY
    ↓
Keep total <= 1000
    ↓
Find the last one
```

---

# Why Can't We Put `total_weight <= 1000` in the Inner `WHERE`?

We cannot do:

```sql id="k9v3rx"
WHERE SUM(weight) OVER (ORDER BY turn) <= 1000
```

because window functions are calculated **after the `WHERE` phase** of the query.

So SQL needs us to first calculate the window-function result and then filter it in an outer query.

That's why we use:

```sql id="j4s8pd"
FROM (
    SELECT ...
           SUM(weight) OVER (...) AS total_weight
    FROM Queue
) q
WHERE total_weight <= 1000
```

---

# Why `SUM()` Instead of `AVG()` or `COUNT()`?

The bus has a **weight limit**, so we need the cumulative sum of weights.

For example:

```text id="w6k2fz"
250 + 350 + 400 = 1000
```

Therefore:

```sql id="u3c9hm"
SUM(weight)
```

is the appropriate aggregate function.

---

# Why `ORDER BY turn` Inside `OVER()`?

This is one of the most important parts of the problem.

We write:

```sql id="x7q4nb"
SUM(weight) OVER (ORDER BY turn)
```

not simply:

```sql id="y2v6md"
SUM(weight) OVER ()
```

Without `ORDER BY turn`, the window function would calculate the same overall total for every row.

We specifically need a **running total in boarding order**.

So:

```sql id="c5n8jr"
ORDER BY turn
```

tells SQL:

> Start with the person at turn 1, then turn 2, then turn 3, and so on.

---

# Why `ORDER BY turn DESC` in the Outer Query?

The inner query uses:

```sql id="p8s4fk"
ORDER BY turn
```

to calculate the running total in the correct boarding order.

The outer query uses:

```sql id="r2m7yc"
ORDER BY turn DESC
```

for a completely different reason:

> Once we know who fits, put the latest boarding turn first.

For example:

```text id="q6n1wp"
Alice      → turn 1
Alex       → turn 2
John Cena  → turn 3
```

Descending order gives:

```text id="b3f8vt"
John Cena  → turn 3
Alex       → turn 2
Alice      → turn 1
```

Then:

```sql id="x9k5hd"
LIMIT 1
```

returns John Cena.

---

# Example Walkthrough

Given:

| turn | person_name | weight |
| ---: | ----------- | -----: |
|    1 | Alice       |    250 |
|    2 | Alex        |    350 |
|    3 | John Cena   |    400 |
|    4 | Marie       |    200 |
|    5 | Bob         |    175 |
|    6 | Winston     |    500 |

### Turn 1

```text id="m2q7vb"
250
```

Total:

```text id="n4w8cx"
250
```

Fits.

---

### Turn 2

```text id="r6t1kp"
250 + 350 = 600
```

Total:

```text id="s9v3hm"
600
```

Fits.

---

### Turn 3

```text id="f5j8qa"
250 + 350 + 400 = 1000
```

Total:

```text id="d2k7wx"
1000
```

Fits exactly.

John Cena is currently the last person who can board.

---

### Turn 4

```text id="g8m1zr"
250 + 350 + 400 + 200 = 1200
```

Total:

```text id="h3p6sy"
1200
```

Exceeds the limit.

Marie cannot board.

Since everyone after Marie would have an even larger cumulative weight, they cannot become the last person who fits either.

Therefore, the answer is:

```text id="j5q9vn"
John Cena
```

---

# Alternative Solution: Correlated Subquery

The same problem can also be solved without a window function:

```sql id="c8w4mz"
SELECT q1.person_name
FROM Queue q1
WHERE (
    SELECT SUM(q2.weight)
    FROM Queue q2
    WHERE q2.turn <= q1.turn
) <= 1000
ORDER BY q1.turn DESC
LIMIT 1;
```

### Explanation

For each person `q1`, the subquery calculates:

> The total weight of everyone who boards up to and including this person's turn.

The condition:

```sql id="z6r2pk"
q2.turn <= q1.turn
```

means that if we are checking the person at turn `3`, we add the weights of turns:

```text id="v4n8tx"
1 + 2 + 3
```

For turn `4`, we calculate:

```text id="k7m3qs"
1 + 2 + 3 + 4
```

Then:

```sql id="a1f5yc"
<= 1000
```

keeps only people who can fit.

Finally:

```sql id="e9t2vw"
ORDER BY q1.turn DESC
LIMIT 1
```

returns the last person who fits.

---

# Which Solution Should You Remember?

The **window-function solution** is the best one to remember:

```sql id="r4x8nd"
SELECT person_name
FROM (
    SELECT person_name,
           turn,
           SUM(weight) OVER (ORDER BY turn) AS total_weight
    FROM Queue
) q
WHERE total_weight <= 1000
ORDER BY turn DESC
LIMIT 1;
```

The reason is that the problem is fundamentally asking for a **running/cumulative total**.

Whenever you see:

* cumulative total
* running sum
* running count
* total up to the current row
* previous rows + current row

think:

```sql id="t7v2hm"
SUM(...) OVER (ORDER BY ...)
```

---

## Key Takeaway

The core logic is:

```text id="x3k8pn"
Order people by turn
        ↓
Calculate cumulative weight
        ↓
Keep cumulative weight <= 1000
        ↓
Find the highest turn
        ↓
Return that person's name
```

The most important SQL pattern is:

```sql id="q6w1zs"
SUM(weight) OVER (ORDER BY turn)
```

which creates a **running total**.

Then:

```sql id="m8r4cy"
WHERE total_weight <= 1000
```

keeps only the people who can fit, and:

```sql id="n2v7ka"
ORDER BY turn DESC
LIMIT 1
```

finds the last person who can board.

### General pattern to remember

For problems asking:

> "Find the last row where a cumulative value stays within a limit"

think:

```sql id="h5j9rx"
SELECT ...
FROM (
    SELECT ...,
           SUM(value) OVER (ORDER BY sequence_column) AS running_total
    FROM table
) t
WHERE running_total <= limit
ORDER BY sequence_column DESC
LIMIT 1;
```
