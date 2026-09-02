# 1045. Customers Who Bought All Products

> **Difficulty:** Medium

## Problem

You are given two tables:

### Table: `Customer`

| Column        | Type |
| ------------- | ---- |
| `customer_id` | int  |
| `product_key` | int  |

`Customer` may contain duplicate rows.

### Table: `Product`

| Column        | Type |
| ------------- | ---- |
| `product_key` | int  |

`product_key` is the primary key of the `Product` table.

The `Customer` table has a foreign key relationship with the `Product` table.

A customer **bought all products** if they have purchased **every product** listed in the `Product` table.

Return the `customer_id` of every customer who bought all products.

---

## Solution 1: `COUNT(DISTINCT)` + Subquery

```sql
SELECT customer_id
FROM Customer
GROUP BY customer_id
HAVING COUNT(DISTINCT product_key) = (
    SELECT COUNT(*)
    FROM Product
);
```

### Explanation

The key idea is:

> A customer bought **all products** if the number of **different products they bought** equals the **total number of products available**.

### Step 1: Count the total number of products

```sql
SELECT COUNT(*)
FROM Product;
```

This gives us the total number of products in the `Product` table.

For example:

| product_key |
| ----------- |
| 10          |
| 20          |
| 30          |

The result is:

```text
3
```

So a customer must have purchased **3 different products** to have bought everything.

---

### Step 2: Group purchases by customer

```sql
GROUP BY customer_id
```

This puts all purchases belonging to the same customer into one group.

For example:

| customer_id | product_key |
| ----------- | ----------- |
| 1           | 10          |
| 1           | 20          |
| 1           | 30          |
| 2           | 10          |
| 2           | 20          |

After grouping, we can calculate how many products each customer purchased.

---

### Step 3: Count distinct products

```sql
COUNT(DISTINCT product_key)
```

This counts the **unique products** purchased by each customer.

We use `DISTINCT` because the `Customer` table may contain duplicate rows.

For example:

| customer_id | product_key |
| ----------- | ----------- |
| 1           | 10          |
| 1           | 10          |
| 1           | 20          |
| 1           | 30          |

Customer `1` purchased products `10`, `20`, and `30`.

So:

```sql
COUNT(DISTINCT product_key)
```

returns:

```text
3
```

rather than `4`.

---

### Step 4: Compare with the total number of products

```sql
HAVING COUNT(DISTINCT product_key) = (
    SELECT COUNT(*)
    FROM Product
)
```

Suppose there are 3 products in total.

Then:

* Customer 1 bought 3 different products → `3 = 3` → included
* Customer 2 bought 2 different products → `2 = 3` → excluded

`HAVING` is used because we are filtering based on an aggregate value (`COUNT`).

---

## Why `HAVING` instead of `WHERE`?

`WHERE` filters individual rows **before** grouping.

`HAVING` filters groups **after** aggregation.

Since:

```sql
COUNT(DISTINCT product_key)
```

is calculated after `GROUP BY`, we need:

```sql
HAVING
```

rather than:

```sql
WHERE
```

---

## Why do we need `DISTINCT`?

Consider:

```text
Customer

customer_id | product_key
------------|------------
1           | 10
1           | 10
1           | 20
1           | 30
```

There are 4 rows, but the customer only bought 3 different products.

Therefore:

```sql
COUNT(product_key)
```

would return:

```text
4
```

while:

```sql
COUNT(DISTINCT product_key)
```

returns:

```text
3
```

Since the question is asking whether the customer bought **every product**, we care about the number of **unique products**, not the number of purchase records.

---

# Solution 2: `NOT EXISTS`

Another way to think about the problem is:

> A customer bought all products if there is **no product that they failed to buy**.

```sql
SELECT DISTINCT c.customer_id
FROM Customer c
WHERE NOT EXISTS (
    SELECT 1
    FROM Product p
    WHERE NOT EXISTS (
        SELECT 1
        FROM Customer c2
        WHERE c2.customer_id = c.customer_id
          AND c2.product_key = p.product_key
    )
);
```

### Explanation

This solution directly expresses the meaning of **"bought all products."**

For each customer:

1. Look at every product.
2. Check whether the customer bought that product.
3. Find products that the customer did **not** buy.
4. If no such product exists, the customer bought everything.

The important part is:

```sql
WHERE NOT EXISTS (
    SELECT 1
    FROM Customer c2
    WHERE c2.customer_id = c.customer_id
      AND c2.product_key = p.product_key
)
```

This checks whether a particular customer has a purchase record for a particular product.

The outer `NOT EXISTS` then says:

> There must not exist any product for which the customer has no purchase record.

This is a common SQL pattern for questions containing words like:

* **all**
* **every**
* **each**
* **none**

---

# Solution 3: `JOIN` + `GROUP BY`

We can also join the two tables and count the products associated with each customer.

```sql
SELECT c.customer_id
FROM Customer c
JOIN Product p
    ON c.product_key = p.product_key
GROUP BY c.customer_id
HAVING COUNT(DISTINCT c.product_key) = (
    SELECT COUNT(*)
    FROM Product
);
```

### Explanation

The `JOIN` connects each purchase in `Customer` with the corresponding product in `Product`.

```sql
JOIN Product p
    ON c.product_key = p.product_key
```

The foreign key relationship ensures that `Customer.product_key` refers to a valid product.

We then group by customer:

```sql
GROUP BY c.customer_id
```

and count how many unique products each customer has purchased:

```sql
COUNT(DISTINCT c.product_key)
```

Finally, we compare that count with the total number of products:

```sql
HAVING COUNT(DISTINCT c.product_key) = (
    SELECT COUNT(*)
    FROM Product
)
```

If the numbers are equal, that customer has bought every product.

---

## What does the Foreign Key tell us?

The `Customer` table has a relationship with the `Product` table through:

```text
Customer.product_key
        ↓
Product.product_key
```

This means a `product_key` appearing in `Customer` corresponds to a product in `Product`.

However, the foreign key itself does **not** mean that a customer bought every product.

It only tells us that the product being referenced is valid.

We still need to compare:

```text
products bought by customer
```

with:

```text
total products
```

to determine whether they bought **all** products.

---

## The Main Pattern to Remember

For problems asking:

> "Find customers/users who did **all** of X"

a very useful approach is:

```sql
SELECT group_column
FROM table
GROUP BY group_column
HAVING COUNT(DISTINCT item_column) = (
    SELECT COUNT(*)
    FROM item_table
);
```

In this problem:

```text
group_column  → customer_id
item_column   → product_key
item_table    → Product
```

So the logic becomes:

```text
unique products bought by customer
                =
total products available
```

If those numbers are equal, the customer bought **all products**.

---

## Key Takeaway

The most straightforward solution is:

```sql
SELECT customer_id
FROM Customer
GROUP BY customer_id
HAVING COUNT(DISTINCT product_key) = (
    SELECT COUNT(*)
    FROM Product
);
```

The important concepts are:

* `GROUP BY` → analyze each customer separately
* `COUNT(DISTINCT ...)` → count unique products purchased
* `COUNT(*)` → count the total products available
* `HAVING` → filter customers based on the aggregate count
* Subquery → obtain the total number of products
* `DISTINCT` → avoid duplicate purchase records affecting the result

### Think of "bought all products" as:

```text
unique products bought
        =
total products
```

That simple comparison is the core idea behind the problem.
