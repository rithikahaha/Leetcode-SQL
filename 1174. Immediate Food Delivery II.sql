# 1174. Immediate Food Delivery II

> **Difficulty:** Medium

## Problem

Find the percentage of **immediate orders among the first orders of all customers**.

An order is **immediate** if:

```text
order_date = customer_pref_delivery_date
```

Otherwise, the order is **scheduled**.

The **first order** of a customer is the order with the earliest `order_date`.

The result should be rounded to **2 decimal places**.

### Table: Delivery

| Column | Type |
|--------|------|
| delivery_id | int |
| customer_id | int |
| order_date | date |
| customer_pref_delivery_date | date |

---

## Solution 1: Using `MIN()` and Subquery

```sql
SELECT ROUND(
           AVG(order_date = customer_pref_delivery_date) * 100,
           2
       ) AS immediate_percentage
FROM Delivery
WHERE (customer_id, order_date) IN (
    SELECT customer_id,
           MIN(order_date)
    FROM Delivery
    GROUP BY customer_id
);
```

### Explanation

The main challenge in this problem is identifying the **first order for each customer**.

Once we have the first orders, calculating the percentage of immediate orders is straightforward.

### Step 1: Find the first order date for each customer

```sql
SELECT customer_id,
       MIN(order_date)
FROM Delivery
GROUP BY customer_id
```

`MIN(order_date)` finds the earliest order date for each customer.

For the example:

| customer_id | first order date |
|-------------|-----------------|
| 1 | 2019-08-01 |
| 2 | 2019-08-02 |
| 3 | 2019-08-21 |
| 4 | 2019-08-09 |

The problem guarantees that every customer has **exactly one first order**, so each customer corresponds to one first-order record.

### Step 2: Keep only the first orders

```sql
WHERE (customer_id, order_date) IN (
    ...
)
```

The tuple:

```sql
(customer_id, order_date)
```

is compared against the customer and their earliest order date returned by the subquery.

This leaves only the first order of each customer.

For example:

| customer_id | order_date | preferred date |
|-------------|------------|----------------|
| 1 | 2019-08-01 | 2019-08-02 |
| 2 | 2019-08-02 | 2019-08-02 |
| 3 | 2019-08-21 | 2019-08-22 |
| 4 | 2019-08-09 | 2019-08-09 |

### Step 3: Identify immediate orders

```sql
order_date = customer_pref_delivery_date
```

In MySQL, this comparison returns:

- `1` (`TRUE`) if the order is immediate.
- `0` (`FALSE`) if the order is scheduled.

For the example:

| customer_id | immediate? |
|-------------|-----------:|
| 1 | 0 |
| 2 | 1 |
| 3 | 0 |
| 4 | 1 |

### Step 4: Calculate the percentage

```sql
AVG(order_date = customer_pref_delivery_date)
```

Since the boolean expression produces `1` or `0`, `AVG()` gives the proportion of immediate orders.

For the example:

```text
(0 + 1 + 0 + 1) / 4
= 0.50
```

Multiplying by `100` gives:

```text
50.00%
```

Finally:

```sql
ROUND(..., 2)
```

rounds the result to two decimal places.

> **Note:** This is a useful SQL pattern: use `AVG(boolean_condition)` when you need the **percentage/proportion of rows satisfying a condition** in MySQL.

---

## Solution 2: Using `ROW_NUMBER()`

```sql
SELECT ROUND(
           AVG(order_date = customer_pref_delivery_date) * 100,
           2
       ) AS immediate_percentage
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY customer_id
               ORDER BY order_date
           ) AS rn
    FROM Delivery
) AS d
WHERE rn = 1;
```

### Explanation

This solution uses the `ROW_NUMBER()` window function to identify the first order of every customer.

### Step 1: Partition by customer

```sql
PARTITION BY customer_id
```

This creates a separate window for each customer.

For example:

```text
Customer 1 → their orders
Customer 2 → their orders
Customer 3 → their orders
...
```

`ROW_NUMBER()` then starts numbering from `1` separately within each customer.

### Step 2: Order each customer's orders

```sql
ORDER BY order_date
```

The orders are sorted from earliest to latest date.

For example, Customer 3 has:

| order_date | row number |
|------------|-----------:|
| 2019-08-21 | 1 |
| 2019-08-24 | 2 |

Therefore, the earliest order receives:

```text
rn = 1
```

### Step 3: Keep only the first orders

The subquery creates:

```sql
ROW_NUMBER() ... AS rn
```

Then the outer query uses:

```sql
WHERE rn = 1
```

to keep only the first order for every customer.

Now the table contains exactly **one row per customer**.

### Step 4: Calculate the immediate percentage

Once only the first orders remain:

```sql
AVG(order_date = customer_pref_delivery_date)
```

calculates the proportion of first orders that are immediate.

Multiplying by `100` converts the proportion into a percentage.

Finally:

```sql
ROUND(..., 2)
```

rounds the answer to two decimal places.

> **Note:** `ROW_NUMBER()` is especially useful when the problem asks for the **first, last, top, or bottom row within each group**. The general pattern is:
>
> ```sql
> ROW_NUMBER() OVER (
>     PARTITION BY group_column
>     ORDER BY some_column
> )
> ```
>
> Then filter the result with `WHERE rn = 1`.

---

## Solution 3: Using `RANK()`

```sql
SELECT ROUND(
           AVG(order_date = customer_pref_delivery_date) * 100,
           2
       ) AS immediate_percentage
FROM (
    SELECT *,
           RANK() OVER (
               PARTITION BY customer_id
               ORDER BY order_date
           ) AS rnk
    FROM Delivery
) AS d
WHERE rnk = 1;
```

### Explanation

This solution uses `RANK()` in the same general way as `ROW_NUMBER()`.

```sql
RANK() OVER (
    PARTITION BY customer_id
    ORDER BY order_date
)
```

assigns rank `1` to the earliest order date for each customer.

Then:

```sql
WHERE rnk = 1
```

keeps the first orders.

After that, the query calculates the percentage of those orders that are immediate.

> **Important:** `ROW_NUMBER()` and `RANK()` behave differently when there are ties. `RANK()` gives the same rank to tied rows, while `ROW_NUMBER()` gives every row a unique number. In this problem, it is guaranteed that every customer has precisely one first order, so either approach works.

---

## Key Takeaway

The most important part of this problem is recognizing that it is a **"first row per group"** problem.

There are two major ways to think about it:

### Using aggregation

```sql
MIN(order_date)
GROUP BY customer_id
```

Find the earliest date for every customer.

### Using a window function

```sql
ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY order_date
)
```

Number each customer's orders chronologically and keep `rn = 1`.

Once the first orders have been isolated, the percentage calculation is simply:

```sql
AVG(condition) * 100
```
