# 1934. Confirmation Rate

> **Difficulty:** Medium

## Problem

The **confirmation rate** of a user is defined as:

```
Number of confirmed messages
--------------------------------
Total confirmation requests
```

If a user has **not requested any confirmation messages**, their confirmation rate is **0**.

Return the `user_id` and the `confirmation_rate` rounded to **2 decimal places**.

### Table: Signups

| Column | Type |
|--------|------|
| user_id | int |
| time_stamp | datetime |

### Table: Confirmations

| Column | Type |
|--------|------|
| user_id | int |
| time_stamp | datetime |
| action | ENUM ('confirmed', 'timeout') |

---

## Solution 1: Using `LEFT JOIN` and `AVG()`

```sql
SELECT s.user_id,
       ROUND(
           IFNULL(AVG(c.action = 'confirmed'), 0),
           2
       ) AS confirmation_rate
FROM Signups s
LEFT JOIN Confirmations c
ON s.user_id = c.user_id
GROUP BY s.user_id;
```

### Explanation

This solution uses the fact that in MySQL:

- `TRUE` is treated as **1**
- `FALSE` is treated as **0**

#### Step 1: Join the tables

```sql
FROM Signups s
LEFT JOIN Confirmations c
ON s.user_id = c.user_id
```

A `LEFT JOIN` returns **all users** from the `Signups` table.

- If a user has confirmation records, they are joined.
- If a user has no confirmation records, all columns from `Confirmations` become `NULL`.

This ensures that users with **no confirmation requests** are still included in the result.

#### Step 2: Evaluate each confirmation

```sql
c.action = 'confirmed'
```

This expression returns:

| action | Result |
|---------|-------:|
| confirmed | 1 |
| timeout | 0 |

For example:

| action |
|---------|
| confirmed |
| confirmed |
| timeout |

becomes

| value |
|------:|
| 1 |
| 1 |
| 0 |

#### Step 3: Calculate the average

```sql
AVG(c.action = 'confirmed')
```

Since `AVG()` is calculated as:

```
SUM(values) / COUNT(values)
```

it automatically computes:

```
number of confirmed messages
--------------------------------
total confirmation requests
```

For example:

| Values | Average |
|--------|--------:|
| 1, 1, 1 | 1.00 |
| 1, 0 | 0.50 |
| 0, 0 | 0.00 |

So `AVG()` directly gives the confirmation rate.

#### Step 4: Handle users with no confirmations

If a user has **no confirmation requests**, the `LEFT JOIN` produces:

| action |
|---------|
| NULL |

Then

```sql
AVG(NULL)
```

returns

```text
NULL
```

To satisfy the problem requirement, replace it with `0`:

```sql
IFNULL(AVG(...), 0)
```

#### Step 5: Round the result

```sql
ROUND(..., 2)
```

rounds the confirmation rate to **2 decimal places**.

> **Note:** This is the most elegant solution because `AVG()` automatically calculates the ratio of confirmed messages to total confirmation requests without explicitly using `COUNT()` or division.

---

## Solution 2: Using `COUNT()` and `SUM()`

```sql
SELECT s.user_id,
       ROUND(
           IFNULL(
               SUM(c.action = 'confirmed') / COUNT(c.action),
               0
           ),
           2
       ) AS confirmation_rate
FROM Signups s
LEFT JOIN Confirmations c
ON s.user_id = c.user_id
GROUP BY s.user_id;
```

### Explanation

This solution computes the confirmation rate using the formula directly.

#### Step 1: Count confirmed messages

```sql
SUM(c.action = 'confirmed')
```

Since:

- `'confirmed'` evaluates to **1**
- `'timeout'` evaluates to **0**

`SUM()` counts the total number of confirmed messages.

For example:

| action |
|---------|
| confirmed |
| timeout |
| confirmed |

becomes

```
1 + 0 + 1 = 2
```

#### Step 2: Count total requests

```sql
COUNT(c.action)
```

counts every confirmation request because `action` is never `NULL` for existing confirmation records.

#### Step 3: Calculate the confirmation rate

```sql
SUM(...) / COUNT(...)
```

computes:

```
confirmed requests
--------------------
total requests
```

#### Step 4: Handle users with no requests

For users with no confirmation records:

- `SUM(...)` returns `NULL`
- `COUNT(...)` returns `0`

Therefore:

```sql
IFNULL(..., 0)
```

returns `0` as required.

Finally,

```sql
ROUND(..., 2)
```

rounds the result to two decimal places.

> **Note:** While this solution is more explicit, the `AVG()` approach is shorter and easier to read because it performs the same calculation internally.

---

## Solution 3: Using `CASE`

```sql
SELECT s.user_id,
       ROUND(
           IFNULL(
               AVG(
                   CASE
                       WHEN c.action = 'confirmed' THEN 1
                       ELSE 0
                   END
               ),
               0
           ),
           2
       ) AS confirmation_rate
FROM Signups s
LEFT JOIN Confirmations c
ON s.user_id = c.user_id
GROUP BY s.user_id;
```

### Explanation

Instead of relying on MySQL treating boolean expressions as `1` and `0`, this solution uses a `CASE` expression.

```sql
CASE
    WHEN action = 'confirmed' THEN 1
    ELSE 0
END
```

converts the values into:

| action | value |
|---------|------:|
| confirmed | 1 |
| timeout | 0 |

`AVG()` then calculates the confirmation rate exactly as in Solution 1.

> **Note:** This approach is more portable because not every SQL database treats boolean expressions as numeric values. Using `CASE` makes the logic explicit and works across most SQL databases.
