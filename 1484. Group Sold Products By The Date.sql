# 1484. Group Sold Products By The Date

> **Difficulty:** Easy

## Problem

We need to group the `Activities` table by `sell_date` and return:

1. The number of **different products** sold on each date.
2. The names of those different products, combined into a single comma-separated string.
3. The product names must be sorted **lexicographically**.
4. The final result must be ordered by `sell_date`.

### Table: `Activities`

| Column Name | Type    | Description               |
| ----------- | ------- | ------------------------- |
| `sell_date` | date    | Date the product was sold |
| `product`   | varchar | Product name              |

> **Important:** The table can contain duplicate rows, so the same product can appear multiple times on the same date.

### Example

For:

| sell_date  | product    |
| ---------- | ---------- |
| 2020-05-30 | Headphone  |
| 2020-05-05 | Basketball |
| 2020-05-30 | Basketball |
| 2020-05-30 | T-Shirt    |
| 2020-05-30 | Headphone  |

The distinct products sold on `2020-05-30` are:

```text
Basketball, Headphone, T-Shirt
```

So:

```text
num_sold = 3
products = Basketball,Headphone,T-Shirt
```

---

# Solution 1: `GROUP_CONCAT()` + `COUNT(DISTINCT)`

```sql
SELECT
    sell_date,
    COUNT(DISTINCT product) AS num_sold,
    GROUP_CONCAT(
        DISTINCT product
        ORDER BY product
        SEPARATOR ','
    ) AS products
FROM Activities
GROUP BY sell_date
ORDER BY sell_date;
```

### Explanation

This solution uses three important concepts:

* `GROUP BY`
* `COUNT(DISTINCT ...)`
* `GROUP_CONCAT(...)`

---

## Step 1: Group rows by date

```sql
GROUP BY sell_date
```

We want **one output row per date**.

For example:

| sell_date  | product    |
| ---------- | ---------- |
| 2020-05-30 | Headphone  |
| 2020-05-30 | Basketball |
| 2020-05-30 | T-Shirt    |
| 2020-06-01 | Pencil     |
| 2020-06-01 | Bible      |

After:

```sql
GROUP BY sell_date
```

we conceptually have:

```text
2020-05-30 → Headphone, Basketball, T-Shirt
2020-06-01 → Pencil, Bible
```

So `GROUP BY` determines the **level at which we want the result**.

Here:

> One row = one `sell_date`.

---

# Step 2: Count different products

```sql
COUNT(DISTINCT product) AS num_sold
```

The word **different** in the problem tells us that we need `DISTINCT`.

Suppose the data contains:

| sell_date  | product |
| ---------- | ------- |
| 2020-06-02 | Mask    |
| 2020-06-02 | Mask    |
| 2020-06-02 | Mask    |

A normal:

```sql
COUNT(product)
```

would return:

```text
3
```

But there is only **one different product**.

Therefore:

```sql
COUNT(DISTINCT product)
```

returns:

```text
1
```

This is exactly what the problem requires.

---

# Step 3: Combine product names

We need the product names to appear in a single column:

```text
Basketball,Headphone,T-Shirt
```

For this, MySQL provides:

```sql
GROUP_CONCAT()
```

So:

```sql
GROUP_CONCAT(product)
```

combines multiple values into one string.

For example:

```text
Basketball
Headphone
T-Shirt
```

becomes:

```text
Basketball,Headphone,T-Shirt
```

---

# Step 4: Remove duplicate products

The table may contain duplicate products on the same date.

For example:

| sell_date  | product |
| ---------- | ------- |
| 2020-06-02 | Mask    |
| 2020-06-02 | Mask    |

We only want:

```text
Mask
```

not:

```text
Mask,Mask
```

Therefore we use:

```sql
GROUP_CONCAT(DISTINCT product ...)
```

The `DISTINCT` inside `GROUP_CONCAT()` removes duplicate product names within each date.

Notice that we need `DISTINCT` **twice**, for two different reasons:

```sql
COUNT(DISTINCT product)
```

removes duplicates when **counting**.

```sql
GROUP_CONCAT(DISTINCT product ...)
```

removes duplicates when **listing the names**.

---

# Step 5: Sort the product names lexicographically

The problem says:

> The sold products names for each date should be sorted lexicographically.

We do that inside `GROUP_CONCAT()`:

```sql
ORDER BY product
```

So if the products are:

```text
T-Shirt
Headphone
Basketball
```

they become:

```text
Basketball
Headphone
T-Shirt
```

Therefore:

```sql
GROUP_CONCAT(
    DISTINCT product
    ORDER BY product
    SEPARATOR ','
)
```

means:

> Take the distinct product names, sort them alphabetically, and join them with commas.

---

# Step 6: Use a comma as the separator

By default, `GROUP_CONCAT()` already uses a comma.

But we explicitly write:

```sql
SEPARATOR ','
```

to make the intended output clear.

For example:

```sql
GROUP_CONCAT(product SEPARATOR ',')
```

produces:

```text
Basketball,Headphone,T-Shirt
```

rather than putting spaces or another separator between values.

---

# Step 7: Order the final result by date

Finally:

```sql
ORDER BY sell_date;
```

makes sure the output dates are in ascending order.

So:

```text
2020-05-30
2020-06-01
2020-06-02
```

rather than an arbitrary order.

---

# Complete Breakdown

The query:

```sql
SELECT
    sell_date,
    COUNT(DISTINCT product) AS num_sold,
    GROUP_CONCAT(
        DISTINCT product
        ORDER BY product
        SEPARATOR ','
    ) AS products
FROM Activities
GROUP BY sell_date
ORDER BY sell_date;
```

can be read almost like English:

> **For each date, count the different products and concatenate their distinct names in alphabetical order, then sort the dates.**

---

# Important SQL Concepts

## 1. `COUNT(DISTINCT column)`

Use:

```sql
COUNT(DISTINCT product)
```

when the question asks for the number of **unique/different/distinct** values.

For example:

| product |
| ------- |
| Mask    |
| Mask    |
| Pencil  |

```sql
COUNT(product)
```

returns:

```text
3
```

while:

```sql
COUNT(DISTINCT product)
```

returns:

```text
2
```

because there are only two different products:

```text
Mask
Pencil
```

---

## 2. `GROUP_CONCAT()`

`GROUP_CONCAT()` is used to combine values from multiple rows into a single string.

For:

| product    |
| ---------- |
| Basketball |
| Headphone  |
| T-Shirt    |

this:

```sql
GROUP_CONCAT(product)
```

produces:

```text
Basketball,Headphone,T-Shirt
```

It is especially useful in SQL problems where the expected output asks you to **list multiple values in one column**.

---

## 3. `GROUP_CONCAT(DISTINCT ...)`

If duplicates are possible, use:

```sql
GROUP_CONCAT(DISTINCT product)
```

For:

```text
Mask
Mask
Pencil
```

it produces:

```text
Mask,Pencil
```

rather than:

```text
Mask,Mask,Pencil
```

---

## 4. `ORDER BY` inside `GROUP_CONCAT()`

There are actually **two different sorting requirements** in this problem.

### Sort products within each date

This:

```sql
GROUP_CONCAT(
    DISTINCT product
    ORDER BY product
)
```

sorts the product names.

### Sort the output dates

This:

```sql
ORDER BY sell_date
```

sorts the final rows.

These two `ORDER BY` clauses have different purposes.

---

## 5. `GROUP BY` vs `ORDER BY`

This distinction is important.

### `GROUP BY`

```sql
GROUP BY sell_date
```

determines **which rows are combined together**.

It creates one group for each date.

### `ORDER BY`

```sql
ORDER BY sell_date
```

determines **the order in which the final groups are displayed**.

So:

```sql
GROUP BY sell_date
```

→ "Make one group per date."

```sql
ORDER BY sell_date
```

→ "Display those dates in ascending order."

---

# Why We Cannot Use Just `COUNT(product)`

Consider:

| sell_date  | product |
| ---------- | ------- |
| 2020-06-02 | Mask    |
| 2020-06-02 | Mask    |
| 2020-06-02 | Pencil  |

The question asks for the number of **different products**.

The answer is:

```text
2
```

not:

```text
3
```

Therefore:

```sql
COUNT(DISTINCT product)
```

is necessary.

---

# Why We Need `DISTINCT` in `GROUP_CONCAT()` Too

It is tempting to write:

```sql
GROUP_CONCAT(product)
```

but this would preserve duplicates.

For:

```text
Mask
Mask
Pencil
```

we would get:

```text
Mask,Mask,Pencil
```

The expected result is:

```text
Mask,Pencil
```

Therefore:

```sql
GROUP_CONCAT(DISTINCT product ...)
```

is required.

---

# Key Takeaway

This problem is a great pattern for remembering how to produce **one row per group while also counting and listing unique values**.

### Count unique values

```sql
COUNT(DISTINCT column)
```

### Combine values into one string

```sql
GROUP_CONCAT(column)
```

### Combine unique values in sorted order

```sql
GROUP_CONCAT(
    DISTINCT column
    ORDER BY column
    SEPARATOR ','
)
```

### Full pattern

```sql
SELECT
    group_column,
    COUNT(DISTINCT value_column) AS count_value,
    GROUP_CONCAT(
        DISTINCT value_column
        ORDER BY value_column
        SEPARATOR ','
    ) AS values
FROM table
GROUP BY group_column
ORDER BY group_column;
```

For this problem:

```text
GROUP BY sell_date
        ↓
one group per date
        ↓
COUNT(DISTINCT product)
        ↓
number of different products
        ↓
GROUP_CONCAT(DISTINCT product ORDER BY product)
        ↓
sorted comma-separated product names
```

The most important thing to notice is that **`DISTINCT` is needed both when counting and when concatenating**, because the `Activities` table can contain duplicate rows.
