# 585. Investments in 2016

> **Difficulty:** Medium

## Problem

We are given an `Insurance` table containing policyholders and their investment information.

We need to calculate the **sum of `tiv_2016`** for policyholders who satisfy **both** of these conditions:

1. Their `tiv_2015` value is shared by **at least one other policyholder**.
2. Their `(lat, lon)` location is **unique** — no other policyholder has the same latitude and longitude.

Finally, round the total `tiv_2016` to **2 decimal places**.

### Table: `Insurance`

| Column     | Type  | Description                    |
| ---------- | ----- | ------------------------------ |
| `pid`      | int   | Policy ID; primary key         |
| `tiv_2015` | float | Total investment value in 2015 |
| `tiv_2016` | float | Total investment value in 2016 |
| `lat`      | float | Latitude                       |
| `lon`      | float | Longitude                      |

`lat` and `lon` are guaranteed to be non-NULL.

---

# Solution 1: `GROUP BY` + `HAVING` + `IN`

```sql id="v7m3qp"
SELECT ROUND(SUM(tiv_2016), 2) AS tiv_2016
FROM Insurance
WHERE tiv_2015 IN (
    SELECT tiv_2015
    FROM Insurance
    GROUP BY tiv_2015
    HAVING COUNT(*) > 1
)
AND (lat, lon) IN (
    SELECT lat, lon
    FROM Insurance
    GROUP BY lat, lon
    HAVING COUNT(*) = 1
);
```

### Explanation

This problem has **two independent conditions**.

We can solve each condition separately and then combine them with `AND`.

Think of it as:

```text id="y8l3av"
Condition 1:
tiv_2015 must appear more than once

AND

Condition 2:
(lat, lon) must appear exactly once
```

Then we sum the `tiv_2016` values of the rows that satisfy both.

---

# Part 1: Find `tiv_2015` Values That Are Repeated

```sql id="3c8p7k"
SELECT tiv_2015
FROM Insurance
GROUP BY tiv_2015
HAVING COUNT(*) > 1;
```

### Why `GROUP BY tiv_2015`?

We want to know how many policyholders have each `tiv_2015` value.

For the example:

| tiv_2015 | Number of policyholders |
| -------: | ----------------------: |
|       10 |                       3 |
|       20 |                       1 |

So we group by:

```sql id="9h1m4e"
GROUP BY tiv_2015
```

This creates one group for each distinct `tiv_2015` value.

---

## Why `HAVING COUNT(*) > 1`?

After grouping, we want only values that occur more than once.

```sql id="j6k9w2"
HAVING COUNT(*) > 1
```

gives:

```text id="c4x7ma"
10
```

because `10` appears three times.

The value `20` appears only once, so it is excluded.

### Why `HAVING` instead of `WHERE`?

`COUNT(*)` is an aggregate calculation.

`WHERE` filters **individual rows before grouping**.

`HAVING` filters **groups after aggregation**.

So:

```sql id="jz2m5p"
WHERE
```

is used for conditions on individual rows, while:

```sql id="5v7q4d"
HAVING COUNT(*) > 1
```

is used for conditions on grouped results.

This is a very important SQL distinction.

---

# Part 2: Use Those Values to Filter the Main Table

We now have:

```sql id="c3g8s0"
SELECT tiv_2015
FROM Insurance
GROUP BY tiv_2015
HAVING COUNT(*) > 1
```

which returns all `tiv_2015` values shared by multiple policyholders.

We use it inside:

```sql id="a8f2z6"
WHERE tiv_2015 IN (...)
```

So:

```sql id="d4x0kn"
WHERE tiv_2015 IN (
    SELECT tiv_2015
    FROM Insurance
    GROUP BY tiv_2015
    HAVING COUNT(*) > 1
)
```

means:

> Keep only policyholders whose `tiv_2015` belongs to a value that occurs more than once.

In the example, that means:

```text id="c7qj6v"
tiv_2015 = 10 → keep
tiv_2015 = 20 → remove
```

---

# Part 3: Find Locations That Are Unique

Now we need the second condition:

> The policyholder must not share their city with anyone else.

A city is represented by the pair:

```text id="3z3r4m"
(lat, lon)
```

So we group by **both columns**:

```sql id="q6t1xk"
SELECT lat, lon
FROM Insurance
GROUP BY lat, lon
HAVING COUNT(*) = 1;
```

For the example:

| lat | lon | Count |
| --: | --: | ----: |
|  10 |  10 |     1 |
|  20 |  20 |     2 |
|  40 |  40 |     1 |

Therefore, the unique locations are:

```text id="z4f8v9"
(10,10)
(40,40)
```

---

# Why Do We Group by Both `lat` and `lon`?

The problem defines a location using the pair:

```text id="n4r8y3"
(lat, lon)
```

Both values together identify the city.

For example:

```text id="s7v2x0"
(10, 20)
(10, 30)
```

are different locations.

If we grouped only by `lat`:

```sql id="z5n1cy"
GROUP BY lat
```

we would incorrectly treat them as the same location.

Therefore we need:

```sql id="h3p6x8"
GROUP BY lat, lon
```

---

# Part 4: Keep Only Unique Locations

We use:

```sql id="a6c8w1"
HAVING COUNT(*) = 1
```

This means:

> Only keep latitude/longitude combinations that occur exactly once.

This is different from the first condition.

### First condition

```sql id="7v5q3n"
HAVING COUNT(*) > 1
```

means:

> This `tiv_2015` value must be shared.

### Second condition

```sql id="k2m9q4"
HAVING COUNT(*) = 1
```

means:

> This location must be unique.

---

# Part 5: Filter Using the `(lat, lon)` Pair

We can compare a pair of columns directly:

```sql id="d1x8m6"
AND (lat, lon) IN (
    SELECT lat, lon
    FROM Insurance
    GROUP BY lat, lon
    HAVING COUNT(*) = 1
)
```

This means:

> Keep the row if its `(lat, lon)` pair appears in the list of unique locations.

For example:

```text id="8q4b2c"
(10,10) → unique → keep
(20,20) → duplicated → remove
(40,40) → unique → keep
```

---

# Part 6: Combine the Two Conditions

Now we have:

```sql id="5y0m8x"
WHERE tiv_2015 IN (...)
```

and:

```sql id="0k4q9s"
AND (lat, lon) IN (...)
```

The `AND` is extremely important.

A policyholder must satisfy **both** conditions.

For the example:

| pid | tiv_2015 repeated? | Location unique? | Keep? |
| --: | ------------------ | ---------------- | ----- |
|   1 | Yes                | Yes              | ✅     |
|   2 | No                 | No               | ❌     |
|   3 | Yes                | No               | ❌     |
|   4 | Yes                | Yes              | ✅     |

So only policyholders `1` and `4` remain.

Their `tiv_2016` values are:

```text id="4w7z2n"
5 + 40 = 45
```

---

# Part 7: Calculate the Final Sum

Once the correct rows have been identified:

```sql id="n6p4v8"
SUM(tiv_2016)
```

calculates their total 2016 investment.

For the example:

```text id="g1x7z3"
5 + 40 = 45
```

Finally:

```sql id="q8v2m1"
ROUND(SUM(tiv_2016), 2)
```

rounds the result to two decimal places.

Therefore:

```text id="0m9x7k"
45.00
```

---

# Solution 2: Self Join

We can also solve the problem using self joins.

```sql id="e3k7p1"
SELECT ROUND(SUM(i1.tiv_2016), 2) AS tiv_2016
FROM Insurance i1
WHERE EXISTS (
    SELECT 1
    FROM Insurance i2
    WHERE i1.tiv_2015 = i2.tiv_2015
      AND i1.pid <> i2.pid
)
AND NOT EXISTS (
    SELECT 1
    FROM Insurance i3
    WHERE i1.lat = i3.lat
      AND i1.lon = i3.lon
      AND i1.pid <> i3.pid
);
```

### Explanation

This approach checks the two conditions **row by row** instead of creating grouped lists.

---

## Condition 1: Someone Else Has the Same `tiv_2015`

```sql id="x9k4v2"
EXISTS (
    SELECT 1
    FROM Insurance i2
    WHERE i1.tiv_2015 = i2.tiv_2015
      AND i1.pid <> i2.pid
)
```

This asks:

> Does another policyholder have the same `tiv_2015` value?

The important part is:

```sql id="z1m8c5"
i1.pid <> i2.pid
```

Without this condition, every row would match **itself**.

For example:

```text id="6v0q3n"
pid 1 → tiv_2015 = 10
```

would match:

```text id="p3q7s9"
pid 1 → tiv_2015 = 10
```

But we need another policyholder, so we require different IDs.

---

## Condition 2: Nobody Else Has the Same Location

We use:

```sql id="r8c2m6"
NOT EXISTS (
    SELECT 1
    FROM Insurance i3
    WHERE i1.lat = i3.lat
      AND i1.lon = i3.lon
      AND i1.pid <> i3.pid
)
```

This asks:

> Does another policyholder have the same latitude and longitude?

If someone else exists at the same location, the condition becomes false.

Therefore:

```sql id="b6y1t4"
NOT EXISTS
```

keeps only rows where no other policyholder shares the location.

Again, we need:

```sql id="v2m9k7"
i1.pid <> i3.pid
```

so the policyholder doesn't match their own location.

---

# Solution 3: `COUNT()` Using Window Functions

We can also calculate the counts directly with window functions.

```sql id="k7w3p9"
SELECT ROUND(SUM(tiv_2016), 2) AS tiv_2016
FROM (
    SELECT
        tiv_2016,
        COUNT(*) OVER (PARTITION BY tiv_2015) AS tiv_count,
        COUNT(*) OVER (PARTITION BY lat, lon) AS location_count
    FROM Insurance
) i
WHERE tiv_count > 1
  AND location_count = 1;
```

### Explanation

This approach is particularly useful for understanding the difference between:

```sql id="m8q2v4"
GROUP BY
```

and:

```sql id="r4k6x1"
PARTITION BY
```

---

## `COUNT(*) OVER (PARTITION BY tiv_2015)`

```sql id="n5c9j2"
COUNT(*) OVER (PARTITION BY tiv_2015)
```

counts how many rows have the same `tiv_2015`.

For example:

| pid | tiv_2015 | tiv_count |
| --: | -------: | --------: |
|   1 |       10 |         3 |
|   2 |       20 |         1 |
|   3 |       10 |         3 |
|   4 |       10 |         3 |

So we can simply filter:

```sql id="s7f2x8"
WHERE tiv_count > 1
```

---

## `COUNT(*) OVER (PARTITION BY lat, lon)`

Similarly:

```sql id="a1k6v9"
COUNT(*) OVER (PARTITION BY lat, lon)
```

counts how many policyholders share each location.

For example:

| pid | lat | lon | location_count |
| --: | --: | --: | -------------: |
|   1 |  10 |  10 |              1 |
|   2 |  20 |  20 |              2 |
|   3 |  20 |  20 |              2 |
|   4 |  40 |  40 |              1 |

Then:

```sql id="q4m8z1"
location_count = 1
```

keeps only unique locations.

---

# `GROUP BY` vs `PARTITION BY`

This distinction is very useful.

### `GROUP BY`

```sql id="c9w5r2"
SELECT tiv_2015, COUNT(*)
FROM Insurance
GROUP BY tiv_2015;
```

collapses multiple rows into one row per group.

Example:

```text id="y2k7m4"
10 → 3
20 → 1
```

### `PARTITION BY`

```sql id="p6v3x8"
COUNT(*) OVER (PARTITION BY tiv_2015)
```

does **not** collapse the rows.

Instead, it adds the count to every original row:

```text id="e1n9q5"
pid 1 → tiv_2015 10 → count 3
pid 2 → tiv_2015 20 → count 1
pid 3 → tiv_2015 10 → count 3
pid 4 → tiv_2015 10 → count 3
```

This can make window functions very convenient when we need to filter individual rows based on group-level information.

---

# Which Solution Should You Remember?

The **first solution using `GROUP BY`, `HAVING`, and `IN`** is probably the best one to remember for this problem.

It maps directly to the English requirements:

```text id="t4v8m2"
Same tiv_2015 as someone else
        ↓
GROUP BY tiv_2015
HAVING COUNT(*) > 1

Unique location
        ↓
GROUP BY lat, lon
HAVING COUNT(*) = 1

Both conditions
        ↓
AND

Add qualifying tiv_2016
        ↓
SUM()
```

The window-function solution is also excellent if you're comfortable with window functions.

---

# Important Concept: Repeated vs Unique

This problem is testing two opposite uses of `COUNT()`.

### Find repeated values

```sql id="n7x2c4"
GROUP BY column
HAVING COUNT(*) > 1
```

Meaning:

> Find values that occur multiple times.

### Find unique values

```sql id="b5q8m1"
GROUP BY column
HAVING COUNT(*) = 1
```

Meaning:

> Find values that occur exactly once.

This pattern appears frequently in SQL problems.

---

# Important Concept: Composite Uniqueness

The location is not defined by `lat` alone or `lon` alone.

It is defined by:

```text id="u4c8p2"
(lat, lon)
```

Therefore:

```sql id="z6m1r7"
GROUP BY lat, lon
```

means:

> Treat the combination of latitude and longitude as the identifier for a location.

This is called a **composite key/combination of columns**.

The same concept appears in:

```sql id="g2x9v5"
PRIMARY KEY (movie_id, user_id)
```

where the combination of two columns identifies a unique relationship.

---

# Important Concept: Why `IN` Works Here

This condition:

```sql id="w3k7q1"
tiv_2015 IN (
    SELECT tiv_2015
    FROM Insurance
    GROUP BY tiv_2015
    HAVING COUNT(*) > 1
)
```

can be read almost like English:

> Keep the row if its `tiv_2015` value is **in the list of repeated `tiv_2015` values**.

Similarly:

```sql id="r9v4m6"
(lat, lon) IN (
    SELECT lat, lon
    FROM Insurance
    GROUP BY lat, lon
    HAVING COUNT(*) = 1
)
```

means:

> Keep the row if its location is **in the list of unique locations**.

This is a useful way to think about `IN` with subqueries.

---

# Key Takeaway

The core pattern for this problem is:

```sql id="k1m7x3"
SELECT ROUND(SUM(tiv_2016), 2)
FROM Insurance
WHERE tiv_2015 IN (
    SELECT tiv_2015
    FROM Insurance
    GROUP BY tiv_2015
    HAVING COUNT(*) > 1
)
AND (lat, lon) IN (
    SELECT lat, lon
    FROM Insurance
    GROUP BY lat, lon
    HAVING COUNT(*) = 1
);
```

The logic is:

```text id="q8c4n6"
                Insurance
                    │
          ┌─────────┴─────────┐
          ↓                   ↓
   Same tiv_2015?       Unique location?
          │                   │
 GROUP BY tiv_2015     GROUP BY lat, lon
 HAVING COUNT > 1      HAVING COUNT = 1
          │                   │
          └─────────┬─────────┘
                    ↓
                   AND
                    ↓
              SUM(tiv_2016)
                    ↓
               ROUND(..., 2)
```

The biggest things to remember are:

```text id="m5v9x2"
Repeated value:
GROUP BY column
HAVING COUNT(*) > 1

Unique value:
GROUP BY column
HAVING COUNT(*) = 1

Composite uniqueness:
GROUP BY column1, column2
HAVING COUNT(*) = 1
```

And when multiple conditions must all be satisfied:

```sql id="h2q6w8"
WHERE condition1
  AND condition2
```

This is the main SQL pattern that solves `585. Investments in 2016`.
