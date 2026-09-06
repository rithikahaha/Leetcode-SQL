# 1164. Product Price at a Given Date

> **Difficulty:** Medium

## Problem

You are given a `Products` table containing the price changes for different products.

### Table: `Products`

| Column        | Type |
| ------------- | ---- |
| `product_id`  | int  |
| `new_price`   | int  |
| `change_date` | date |

* `(product_id, change_date)` is the primary key.
* Each row represents a price change for a product on a particular date.
* Initially, **every product has a price of `10`**.
* We need to find the price of every product on **`2019-08-16`**.

Return:

* `product_id`
* `price`

The result can be returned in any order.

---

## Solution 1: `MAX()` + `IFNULL()`

```sql id="q7n4xz"
SELECT product_id,
       IFNULL(
           MAX(CASE
                   WHEN change_date <= '2019-08-16'
                   THEN new_price
               END),
           10
       ) AS price
FROM Products
GROUP BY product_id;
```

### Explanation

The key idea is:

> The price on `2019-08-16` is the price from the **latest price change that happened on or before `2019-08-16`**.

If a product had **no price change before or on `2019-08-16`**, its price is still the initial price of `10`.

So for every product, we need to:

1. Look only at price changes on or before `2019-08-16`.
2. Find the latest one.
3. Take its `new_price`.
4. If no such change exists, use `10`.

---

## Step 1: Understand which price we need

Consider product `1`:

| product_id | new_price | change_date |
| ---------: | --------: | ----------- |
|          1 |        20 | 2019-08-14  |
|          1 |        30 | 2019-08-15  |
|          1 |        35 | 2019-08-16  |

On `2019-08-16`, the price is:

```text id="qj9x8b"
35
```

because `35` is the price from the **most recent change on or before that date**.

The change on `2019-08-17` for product `2`, for example, cannot affect the price on `2019-08-16`.

---

## Step 2: Ignore changes after the target date

We use:

```sql id="xk0j1a"
change_date <= '2019-08-16'
```

This means:

> Only consider price changes that happened on or before `2019-08-16`.

For example, product `2` has:

| new_price | change_date |
| --------: | ----------- |
|        50 | 2019-08-14  |
|        65 | 2019-08-17  |

The second change happened **after** the target date.

So on `2019-08-16`, product `2` still costs:

```text id="jjw2l9"
50
```

---

## Step 3: Use `CASE` to keep only valid price changes

We write:

```sql id="k8w0fk"
CASE
    WHEN change_date <= '2019-08-16'
    THEN new_price
END
```

This means:

```text id="5hqqk6"
If the price change happened on/before August 16
    → keep new_price

Otherwise
    → return NULL
```

For example:

| new_price | change_date | CASE result |
| --------: | ----------- | ----------: |
|        20 | Aug 14      |          20 |
|        30 | Aug 15      |          30 |
|        35 | Aug 16      |          35 |
|        40 | Aug 17      |        NULL |

The price change after the target date is ignored.

---

## Step 4: Find the latest applicable price

Now we use:

```sql id="7apjz4"
MAX(...)
```

Why does `MAX()` give us the correct price?

Because the price changes are associated with dates, and we have already filtered out changes after the target date.

However, there is an important detail:

**Strictly speaking, `MAX(new_price)` is not the same as "price from the latest date."**

The clean way to use `MAX()` here is when we first identify the latest applicable date, not simply the largest price.

Therefore, a more robust solution is to use a subquery that finds the latest date first.

---

# Solution 2: `MAX(change_date)` + Join

```sql id="m8s2cf"
SELECT p.product_id,
       p.new_price AS price
FROM Products p
JOIN (
    SELECT product_id,
           MAX(change_date) AS latest_date
    FROM Products
    WHERE change_date <= '2019-08-16'
    GROUP BY product_id
) latest
    ON p.product_id = latest.product_id
   AND p.change_date = latest.latest_date

UNION

SELECT product_id,
       10 AS price
FROM Products
GROUP BY product_id
HAVING MIN(change_date) > '2019-08-16';
```

### Explanation

This solution handles the problem in two cases:

### Case 1

The product has at least one price change on or before `2019-08-16`.

→ Find its latest such change and use `new_price`.

### Case 2

The product has no price change on or before `2019-08-16`.

→ Its price is still the initial price `10`.

---

## Step 1: Find the latest price change before the target date

```sql id="4z1h4f"
SELECT product_id,
       MAX(change_date) AS latest_date
FROM Products
WHERE change_date <= '2019-08-16'
GROUP BY product_id;
```

For the example data, this produces:

| product_id | latest_date |
| ---------: | ----------- |
|          1 | 2019-08-16  |
|          2 | 2019-08-14  |

Product `3` does not appear because its first price change was on `2019-08-18`, which is after the target date.

---

## Step 2: Join back to the original table

We now need the **price** associated with each `latest_date`.

That's why we join the result back to `Products`:

```sql id="n1s1id"
JOIN (
    ...
) latest
    ON p.product_id = latest.product_id
   AND p.change_date = latest.latest_date
```

For example:

```text id="w8x2qv"
product 1
latest date = 2019-08-16
                 ↓
new_price = 35
```

So product `1` gets price `35`.

---

## Why do we need both conditions in the `JOIN`?

We write:

```sql id="d5q8ot"
ON p.product_id = latest.product_id
AND p.change_date = latest.latest_date
```

We need both because:

```text id="9q2x8b"
product_id
```

tells us **which product** we're looking for, while:

```text id="lq6x5h"
change_date
```

tells us **which price-change row** we're looking for.

Using only:

```sql id="5zq1m0"
p.product_id = latest.product_id
```

would match every historical price change for that product.

We specifically need the row corresponding to the latest date.

---

# Step 3: Handle Products With No Previous Price Change

Product `3` has:

| product_id | new_price | change_date |
| ---------: | --------: | ----------- |
|          3 |        20 | 2019-08-18  |

Its first change happens after `2019-08-16`.

Therefore, on `2019-08-16`, product `3` still has its initial price:

```text id="0qg8xm"
10
```

The second query handles these products:

```sql id="1q2r3s"
SELECT product_id,
       10 AS price
FROM Products
GROUP BY product_id
HAVING MIN(change_date) > '2019-08-16';
```

---

## Why `MIN(change_date)`?

For each product:

```sql id="n4q5v6"
MIN(change_date)
```

gives the **first-ever price change**.

If the first price change is after the target date:

```text id="2x7j5c"
MIN(change_date) > '2019-08-16'
```

then the product had no price changes before or on the target date.

Therefore, its price must still be the initial price of `10`.

---

## Why `HAVING`?

We use:

```sql id="a7b8c9"
GROUP BY product_id
HAVING MIN(change_date) > '2019-08-16'
```

because `MIN(change_date)` is an aggregate calculated for each product.

`HAVING` filters the grouped results after aggregation.

We cannot use:

```sql id="e1f2g3"
WHERE MIN(change_date) > '2019-08-16'
```

because `WHERE` operates before the grouping/aggregation.

---

# Step 4: Combine the Two Cases with `UNION`

The first query returns products that **did have a price change** before/on the target date.

The second query returns products that **did not have a price change** before/on the target date.

We combine them:

```sql id="h4i5j6"
UNION
```

So every product gets exactly one final price.

---

## Example Walkthrough

Given:

| product_id | new_price | change_date |
| ---------: | --------: | ----------- |
|          1 |        20 | 2019-08-14  |
|          2 |        50 | 2019-08-14  |
|          1 |        30 | 2019-08-15  |
|          1 |        35 | 2019-08-16  |
|          2 |        65 | 2019-08-17  |
|          3 |        20 | 2019-08-18  |

Target date:

```text id="j7k8l9"
2019-08-16
```

### Product 1

Changes before/on target date:

```text id="m1n2o3"
2019-08-14 → 20
2019-08-15 → 30
2019-08-16 → 35
```

Latest date:

```text id="p4q5r6"
2019-08-16
```

Therefore:

```text id="s7t8u9"
price = 35
```

---

### Product 2

Changes before/on target date:

```text id="v1w2x3"
2019-08-14 → 50
```

The `65` change happened on `2019-08-17`, which is after the target date.

Therefore:

```text id="y4z5a6"
price = 50
```

---

### Product 3

Its only change is:

```text id="b7c8d9"
2019-08-18 → 20
```

This is after the target date.

Therefore, no price change had happened yet.

Initial price:

```text id="e1f2g3"
10
```

So:

```text id="h4i5j6"
price = 10
```

Final result:

| product_id | price |
| ---------: | ----: |
|          1 |    35 |
|          2 |    50 |
|          3 |    10 |

---

# An Important Idea: "Value at a Given Date"

This problem is a classic **historical state** problem.

Whenever you see wording like:

> "Find the value on a given date"

you should think:

```text id="i7j8k9"
Find changes <= target date
        ↓
Find the latest date
        ↓
Use the value from that row
```

For this problem:

```text id="l1m2n3"
change_date <= '2019-08-16'
        ↓
MAX(change_date)
        ↓
new_price
```

And if no change exists:

```text id="o4p5q6"
initial value = 10
```

---

## Why Can't We Simply Use `MAX(new_price)`?

Suppose a product had:

| new_price | change_date |
| --------: | ----------- |
|       100 | 2019-08-10  |
|        50 | 2019-08-15  |

On `2019-08-16`, the correct price is:

```text id="r7s8t9"
50
```

But:

```sql id="u1v2w3"
MAX(new_price)
```

would return:

```text id="x4y5z6"
100
```

which is wrong.

We care about the **latest date**, not the highest price.

Therefore:

```sql id="a7b8c9"
MAX(change_date)
```

is what we need.

Then we use that date to retrieve its corresponding `new_price`.

---

## Key Takeaway

The core pattern for this problem is:

```text id="d1e2f3"
1. Filter changes up to the target date
2. Find the latest change date for each product
3. Retrieve the price from that date
4. Use the initial price if no earlier change exists
```

The most important SQL concepts are:

* `MAX(change_date)` → finds the latest applicable change.
* `GROUP BY product_id` → performs the calculation separately for each product.
* `JOIN` → retrieves the `new_price` belonging to the latest date.
* `MIN(change_date)` → identifies products whose first change is after the target date.
* `HAVING` → filters grouped products.
* `UNION` → combines products with and without previous price changes.
* Initial price `10` → handles products that had not changed price yet.

### General pattern to remember

For:

> "What was the value of X at date D?"

think:

```sql
SELECT ...
FROM table
JOIN (
    SELECT id,
           MAX(date) AS latest_date
    FROM table
    WHERE date <= target_date
    GROUP BY id
) latest
    ON table.id = latest.id
   AND table.date = latest.latest_date;
```

The key question to ask yourself is:

> **"What is the latest record that existed at the date I'm being asked about?"**

Once you find that record, its value is the answer.
