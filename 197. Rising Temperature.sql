# 197. Rising Temperature

> **Difficulty:** Easy

## Problem

Find the IDs of all dates where the temperature is **higher than the previous day (yesterday)**.

Return the result table in **any order**.

### Table: Weather

| Column | Type |
|--------|------|
| id | int |
| recordDate | date |
| temperature | int |

## Solution 1: Using `DATEDIFF()`

```sql
SELECT w1.id
FROM Weather w1
JOIN Weather w2
ON DATEDIFF(w1.recordDate, w2.recordDate) = 1
WHERE w1.temperature > w2.temperature;
```

### Explanation

A self join is used to compare each day's weather with the previous day's weather.

- `w1` represents the **current day's** record.
- `w2` represents the **previous day's** record.
- `DATEDIFF(w1.recordDate, w2.recordDate) = 1` ensures that `w2` is exactly one day before `w1`.
- The `WHERE` clause filters only those days where the current day's temperature is higher than the previous day's temperature.
- The query returns the `id` of the current day's record.

> **Note:** `DATEDIFF(date1, date2)` returns the number of days between two dates. A result of `1` means `date1` is exactly one day after `date2`.

---

## Solution 2: Using `DATE_SUB()`

```sql
SELECT w1.id
FROM Weather w1
JOIN Weather w2
ON w2.recordDate = DATE_SUB(w1.recordDate, INTERVAL 1 DAY)
WHERE w1.temperature > w2.temperature;
```

### Explanation

This solution uses the `DATE_SUB()` function to calculate yesterday's date.

- `DATE_SUB(w1.recordDate, INTERVAL 1 DAY)` subtracts one day from the current date.
- The join condition matches the current day's record with the previous day's record.
- The `WHERE` clause returns only those records where today's temperature is higher than yesterday's.

This approach is often considered more readable because it explicitly shows that the comparison is with the previous day.

---

## Solution 3: Using `DATE_ADD()`

```sql
SELECT w1.id
FROM Weather w1
JOIN Weather w2
ON w1.recordDate = DATE_ADD(w2.recordDate, INTERVAL 1 DAY)
WHERE w1.temperature > w2.temperature;
```

### Explanation

This solution uses the `DATE_ADD()` function instead of `DATE_SUB()`.

- `DATE_ADD(w2.recordDate, INTERVAL 1 DAY)` adds one day to the previous date.
- The join condition matches the current day's record with yesterday's record.
- The `WHERE` clause filters only those days where the current day's temperature is higher.

`DATE_ADD()` and `DATE_SUB()` produce the same result. The choice between them comes down to readability and personal preference.

---

## Solution 4: Using `INTERVAL`

```sql
SELECT w1.id
FROM Weather w1
JOIN Weather w2
ON w1.recordDate - INTERVAL 1 DAY = w2.recordDate
WHERE w1.temperature > w2.temperature;
```

### Explanation

This solution uses the `INTERVAL` keyword to perform date arithmetic directly.

- `w1.recordDate - INTERVAL 1 DAY` subtracts one day from the current date.
- The join condition matches each day's record with the previous day's record.
- The `WHERE` clause filters only those days where the current day's temperature is higher than yesterday's.

Using `INTERVAL` provides a concise way to perform date arithmetic in MySQL without explicitly calling functions like `DATE_SUB()`.

> **Note:** All three approaches—`DATEDIFF()`, `DATE_SUB()`, and `INTERVAL` arithmetic—produce the same result in MySQL. `DATE_SUB()` and `INTERVAL` express the date relationship directly, while `DATEDIFF()` compares the number of days between two dates.

---

## Solution 5: Using `LAG()`

```sql
SELECT id
FROM (
    SELECT id,
           recordDate,
           temperature,
           LAG(recordDate) OVER (ORDER BY recordDate) AS prev_date,
           LAG(temperature) OVER (ORDER BY recordDate) AS prev_temp
    FROM Weather
) AS w
WHERE DATEDIFF(recordDate, prev_date) = 1
  AND temperature > prev_temp;
```

### Explanation

Unlike the previous solutions, this approach **does not use a self join**. Instead, it uses the `LAG()` window function to retrieve values from the previous row.

#### Step 1: Process the rows in chronological order

```sql
LAG(recordDate) OVER (ORDER BY recordDate)
LAG(temperature) OVER (ORDER BY recordDate)
```

- `ORDER BY recordDate` tells SQL to process the rows in date order.
- Without `ORDER BY`, SQL would not know which row is considered "previous."

#### Step 2: Create the missing columns

The `LAG()` function returns the value from the **previous row**.

```sql
LAG(recordDate) OVER (ORDER BY recordDate) AS prev_date
```

creates a new column:

| recordDate | prev_date |
|------------|-----------|
| 2015-01-01 | NULL |
| 2015-01-02 | 2015-01-01 |
| 2015-01-03 | 2015-01-02 |
| 2015-01-04 | 2015-01-03 |

Similarly,

```sql
LAG(temperature) OVER (ORDER BY recordDate) AS prev_temp
```

creates:

| temperature | prev_temp |
|------------:|----------:|
| 10 | NULL |
| 25 | 10 |
| 20 | 25 |
| 30 | 20 |

Now each row contains both the **current day's** and the **previous day's** information.

#### Step 3: Use a subquery

```sql
SELECT ...
FROM Weather
```

first creates the two new columns (`prev_date` and `prev_temp`).

These aliases cannot be referenced directly in the `WHERE` clause because SQL evaluates `WHERE` **before** `SELECT`.

To solve this, the query wraps the result inside a subquery:

```sql
FROM (
    ...
) AS w
```

Now `prev_date` and `prev_temp` become actual columns that the outer query can use.

#### Step 4: Filter the required rows

```sql
WHERE DATEDIFF(recordDate, prev_date) = 1
AND temperature > prev_temp;
```

The conditions ensure that:

- The previous row corresponds to **yesterday**.
- Today's temperature is higher than yesterday's temperature.

Finally, the query returns the `id` of the current day's record.

> **Note:** `LAG()` simply returns the **previous row**, not necessarily **yesterday's row**. If a date is missing (for example, Jan 2 is absent), the previous row might be Jan 1 instead of yesterday. That's why `DATEDIFF(recordDate, prev_date) = 1` is still required.

> **Note:** `LAG()` is a **window function** available in **MySQL 8.0+**, PostgreSQL, SQL Server, Oracle, and other modern SQL databases. It often produces cleaner and more readable solutions than self joins when comparing adjacent rows.
