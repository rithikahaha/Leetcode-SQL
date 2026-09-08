# 1321. Restaurant Growth

> **Difficulty:** Medium

## Problem

We are given a `Customer` table containing restaurant visits and the amount each customer paid.

We need to calculate a **7-day moving total and moving average**.

For each date:

* `amount` = total amount paid by all customers on that date.
* `average_amount` = average amount paid over the **current day + previous 6 days**.
* Only dates that have a **complete 7-day window** should be returned.
* `average_amount` must be rounded to **2 decimal places**.
* Results must be ordered by `visited_on` ascending.

### Table: `Customer`

| Column        | Type    | Description                 |
| ------------- | ------- | --------------------------- |
| `customer_id` | int     | Customer ID                 |
| `name`        | varchar | Customer name               |
| `visited_on`  | date    | Date of visit               |
| `amount`      | int     | Amount paid by the customer |

The primary key is:

```text
(customer_id, visited_on)
```

This means a customer can appear on multiple different dates, but only once per date.

---

# Solution 1: Window Functions

```sql
SELECT
    visited_on,
    SUM(daily_amount) OVER (
        ORDER BY visited_on
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS amount,
    ROUND(
        AVG(daily_amount) OVER (
            ORDER BY visited_on
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS average_amount
FROM (
    SELECT
        visited_on,
        SUM(amount) AS daily_amount
    FROM Customer
    GROUP BY visited_on
) d
WHERE visited_on >= (
    SELECT DATE_ADD(MIN(visited_on), INTERVAL 6 DAY)
    FROM Customer
)
ORDER BY visited_on;
```

### Explanation

There are **two separate levels of calculation** in this problem.

First, we need to calculate the total amount for **each day**.

Then, we need to calculate the 7-day moving total and average using those daily totals.

That's why we use a subquery.

---

## Step 1: Calculate the Total for Each Day

```sql
SELECT
    visited_on,
    SUM(amount) AS daily_amount
FROM Customer
GROUP BY visited_on
```

The original table can contain multiple customers on the same date.

For example:

| visited_on | amount |
| ---------- | -----: |
| 2019-01-10 |    130 |
| 2019-01-10 |    150 |

The restaurant's total for January 10 is:

```text
130 + 150 = 280
```

So:

```sql
SUM(amount)
```

calculates the total amount collected on that date.

The `GROUP BY`:

```sql
GROUP BY visited_on
```

makes the calculation happen separately for every date.

The subquery therefore produces:

| visited_on | daily_amount |
| ---------- | -----------: |
| 2019-01-01 |          100 |
| 2019-01-02 |          110 |
| 2019-01-03 |          120 |
| 2019-01-04 |          130 |
| 2019-01-05 |          110 |
| 2019-01-06 |          140 |
| 2019-01-07 |          150 |
| 2019-01-08 |           80 |
| 2019-01-09 |          110 |
| 2019-01-10 |          280 |

Notice that January 10 has `280`, because there were two customers that day.

---

# Step 2: Calculate the 7-Day Moving Total

After getting one row per day, we use:

```sql
SUM(daily_amount) OVER (
    ORDER BY visited_on
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
)
```

This is a **window function**.

The important part is:

```sql
ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
```

It means:

> Take the current row and the six rows immediately before it.

That's exactly **7 rows/days**.

For January 7, the window is:

```text
Jan 1
Jan 2
Jan 3
Jan 4
Jan 5
Jan 6
Jan 7
```

So:

```text
100 + 110 + 120 + 130 + 110 + 140 + 150
= 860
```

Therefore:

```text
2019-01-07 → 860
```

For January 8, the window moves forward by one day:

```text
Jan 2
Jan 3
Jan 4
Jan 5
Jan 6
Jan 7
Jan 8
```

and:

```text
110 + 120 + 130 + 110 + 140 + 150 + 80
= 840
```

---

# Step 3: Calculate the Moving Average

We use another window function:

```sql
AVG(daily_amount) OVER (
    ORDER BY visited_on
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
)
```

This calculates the average of the same seven daily totals.

For January 7:

```text
860 / 7
= 122.857...
```

We then round it:

```sql
ROUND(..., 2)
```

giving:

```text
122.86
```

---

## Why Are We Averaging `daily_amount` Instead of `amount`?

This is a **very important point**.

The problem asks for the restaurant's average daily revenue over a 7-day window.

Suppose one day has:

```text
Customer A → $100
Customer B → $100
```

The daily total is:

```text
$200
```

We want that day to contribute **$200** to the 7-day average.

We do **not** want the two customers to count as two separate observations.

Therefore, we first calculate:

```sql
SUM(amount)
```

per day.

Then we calculate:

```sql
AVG(daily_amount)
```

across the seven days.

---

# Step 4: Why `ORDER BY visited_on` Inside `OVER`?

We write:

```sql
SUM(daily_amount) OVER (
    ORDER BY visited_on
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
)
```

The:

```sql
ORDER BY visited_on
```

inside `OVER()` tells SQL how to arrange the rows for the window calculation.

We need chronological order:

```text
Jan 1
Jan 2
Jan 3
Jan 4
...
```

Otherwise SQL would not know which rows are the "previous 6."

---

# Step 5: Why `ROWS BETWEEN 6 PRECEDING AND CURRENT ROW`?

This is one of the most important pieces of the solution.

```sql
ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
```

means:

```text
6 previous rows + current row
```

Therefore:

```text
6 + 1 = 7 rows
```

For example, when processing January 10:

```text
Jan 4 ← 6 preceding
Jan 5
Jan 6
Jan 7
Jan 8
Jan 9
Jan 10 ← current
```

So the window contains exactly seven days.

---

# Step 6: Why Do We Need the `WHERE` Condition?

A 7-day moving average doesn't exist until we have seven days of data.

For example:

```text
Jan 1 → only 1 day
Jan 2 → only 2 days
Jan 3 → only 3 days
...
Jan 6 → only 6 days
Jan 7 → first complete 7-day window
```

Therefore, we don't return January 1–6.

We need the first returned date to be:

```text
minimum date + 6 days
```

We calculate that using:

```sql
SELECT DATE_ADD(MIN(visited_on), INTERVAL 6 DAY)
FROM Customer
```

If the first date is:

```text
2019-01-01
```

then:

```text
2019-01-01 + 6 days
= 2019-01-07
```

So:

```sql
WHERE visited_on >= (
    SELECT DATE_ADD(MIN(visited_on), INTERVAL 6 DAY)
    FROM Customer
)
```

removes the first six dates.

---

# Step 7: Why Does the Problem Say There Is At Least One Customer Every Day?

This is important for the meaning of the 7-day window.

The problem guarantees that there is at least one customer every day.

Therefore, after grouping:

```sql
GROUP BY visited_on
```

there is one row for every calendar date.

So:

```sql
ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
```

really represents **seven consecutive days**.

Without that guarantee, seven rows would not necessarily mean seven calendar days.

For example:

```text
Jan 1
Jan 2
Jan 5
Jan 6
```

would contain four rows but span six calendar days.

The problem avoids this issue by guaranteeing daily visits.

---

# Step 8: Why Is `amount` Named `daily_amount` Inside the Subquery?

Inside the subquery:

```sql
SUM(amount) AS daily_amount
```

we rename the daily total.

This makes the outer query easier to understand:

```sql
SUM(daily_amount)
AVG(daily_amount)
```

rather than trying to perform another `SUM(amount)` directly on the original customer-level data.

The two levels are:

```text
Customer-level data
        ↓
SUM(amount) per day
        ↓
daily_amount
        ↓
7-day SUM / AVG
```

---

# Solution 2: Self Join

The same problem can also be solved without window functions by joining the daily totals to themselves.

```sql
SELECT
    d1.visited_on,
    SUM(d2.daily_amount) AS amount,
    ROUND(AVG(d2.daily_amount), 2) AS average_amount
FROM (
    SELECT
        visited_on,
        SUM(amount) AS daily_amount
    FROM Customer
    GROUP BY visited_on
) d1
JOIN (
    SELECT
        visited_on,
        SUM(amount) AS daily_amount
    FROM Customer
    GROUP BY visited_on
) d2
    ON d2.visited_on BETWEEN DATE_SUB(d1.visited_on, INTERVAL 6 DAY)
                         AND d1.visited_on
GROUP BY d1.visited_on
HAVING COUNT(*) = 7
ORDER BY d1.visited_on;
```

### Explanation

Here we first create the same daily totals:

```sql
SELECT
    visited_on,
    SUM(amount) AS daily_amount
FROM Customer
GROUP BY visited_on
```

We create it twice:

```text
d1
d2
```

These are aliases for the same derived table.

---

## Step 1: Think of `d1` as the Current Day

Suppose:

```text
d1.visited_on = 2019-01-10
```

We want to find all dates from:

```text
2019-01-04
```

through:

```text
2019-01-10
```

That's seven days.

---

## Step 2: Match the Previous Six Days

The join condition is:

```sql
d2.visited_on BETWEEN
    DATE_SUB(d1.visited_on, INTERVAL 6 DAY)
    AND d1.visited_on
```

`DATE_SUB()` subtracts a specified amount of time from a date.

For January 10:

```sql
DATE_SUB('2019-01-10', INTERVAL 6 DAY)
```

gives:

```text
2019-01-04
```

So the condition becomes:

```text
Jan 4 ≤ d2.visited_on ≤ Jan 10
```

which gives:

```text
Jan 4
Jan 5
Jan 6
Jan 7
Jan 8
Jan 9
Jan 10
```

---

## Step 3: Calculate the Total

After the join, all seven daily totals associated with the current day are available.

So:

```sql
SUM(d2.daily_amount)
```

calculates the 7-day total.

For January 10:

```text
130 + 110 + 140 + 150 + 80 + 110 + 280
= 1000
```

---

## Step 4: Calculate the Average

Similarly:

```sql
AVG(d2.daily_amount)
```

calculates the seven-day average.

Then:

```sql
ROUND(AVG(d2.daily_amount), 2)
```

rounds it to two decimal places.

---

## Step 5: Why `HAVING COUNT(*) = 7`?

We only want complete seven-day windows.

```sql
HAVING COUNT(*) = 7
```

ensures that exactly seven daily rows participated in the window.

For January 1:

```text
Only Jan 1
COUNT(*) = 1
```

so it is excluded.

For January 7:

```text
Jan 1 through Jan 7
COUNT(*) = 7
```

so it is included.

Because the problem guarantees at least one customer every day, having seven daily rows means we have a complete seven-day window.

---

# Window Function vs Self Join

The **window-function solution is generally the cleaner solution** for this problem.

### Window function

```sql
SUM(daily_amount) OVER (
    ORDER BY visited_on
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
)
```

directly expresses:

> Give me the current day and previous six days.

The self-join solution instead has to explicitly find those dates using:

```sql
DATE_SUB()
```

and then group the matching rows.

So when a problem asks for:

* moving average
* moving sum
* running total
* previous N rows
* next N rows

you should immediately consider **window functions**.

---

# Important Concept: `ROWS` vs `RANGE`

This problem is a good opportunity to understand the difference between:

```sql
ROWS
```

and:

```sql
RANGE
```

We use:

```sql
ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
```

because we want exactly **seven rows**.

The problem guarantees one row per day after daily aggregation, so those seven rows correspond to seven consecutive days.

`RANGE` works differently: it considers rows based on the value of the ordering column rather than simply counting physical rows.

For this problem, `ROWS` makes the intended seven-row window explicit.

---

# Important Concept: `SUM()` and `AVG()` Can Both Be Window Functions

Normally, we use:

```sql
SUM(amount)
```

with:

```sql
GROUP BY
```

to produce one result per group.

But we can also write:

```sql
SUM(amount) OVER (...)
```

This is a **window aggregate**.

The difference is:

### Regular aggregate

```sql
SELECT
    visited_on,
    SUM(amount)
FROM Customer
GROUP BY visited_on;
```

produces fewer rows:

```text
one row per day
```

### Window aggregate

```sql
SELECT
    visited_on,
    SUM(amount) OVER (...)
FROM Customer;
```

keeps the individual rows while adding a calculated value based on a window.

This distinction is extremely important for SQL interviews.

---

# Key Takeaway

The core pattern for a moving 7-day calculation is:

```sql
AGGREGATE(value) OVER (
    ORDER BY date
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
)
```

For this problem, the complete thought process is:

```text
Customer-level data
        ↓
GROUP BY visited_on
        ↓
SUM(amount) for each day
        ↓
7-day window
        ↓
SUM(daily_amount) → 7-day total
AVG(daily_amount) → 7-day average
        ↓
ROUND(..., 2)
        ↓
Remove first 6 incomplete days
        ↓
ORDER BY visited_on
```

The most important SQL patterns to remember are:

```sql
-- Daily total
SELECT visited_on, SUM(amount)
FROM Customer
GROUP BY visited_on;
```

```sql
-- Moving 7-day total
SUM(daily_amount) OVER (
    ORDER BY visited_on
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
)
```

```sql
-- Moving 7-day average
AVG(daily_amount) OVER (
    ORDER BY visited_on
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
)
```

And the key idea is:

> **When a problem asks for a moving calculation over the previous N rows, window functions with `ROWS BETWEEN ... PRECEDING AND CURRENT ROW` are usually the first approach to consider.**
