# 1661. Average Time of Process per Machine

> **Difficulty:** Easy

## Problem

Find the **average processing time** for each machine.

The processing time for a process is:

```
end timestamp - start timestamp
```

Return the `machine_id` and the average processing time as `processing_time`, rounded to **3 decimal places**.

### Table: Activity

| Column | Type |
|--------|------|
| machine_id | int |
| process_id | int |
| activity_type | enum ('start', 'end') |
| timestamp | float |

## Solution 1: Using Self Join

```sql
SELECT a1.machine_id,
       ROUND(AVG(a2.timestamp - a1.timestamp), 3) AS processing_time
FROM Activity a1
JOIN Activity a2
ON a1.machine_id = a2.machine_id
AND a1.process_id = a2.process_id
WHERE a1.activity_type = 'start'
  AND a2.activity_type = 'end'
GROUP BY a1.machine_id;
```

### Explanation

A self join is used to pair the **start** and **end** records of the same process.

- `a1` represents the **start** record.
- `a2` represents the **end** record.
- The join condition:

```sql
a1.machine_id = a2.machine_id
AND a1.process_id = a2.process_id
```

ensures that the start and end timestamps belong to the **same process running on the same machine**.

- The `WHERE` clause filters the joined rows so that:
  - `a1` contains only the **start** timestamp.
  - `a2` contains only the **end** timestamp.
- `a2.timestamp - a1.timestamp` calculates the processing time for each process.
- `AVG()` calculates the average processing time for each machine.
- `ROUND(..., 3)` rounds the result to **3 decimal places**.
- `GROUP BY machine_id` returns one row for each machine.

---

## Solution 2: Using `LAG()`

```sql
SELECT machine_id,
       ROUND(AVG(process_time), 3) AS processing_time
FROM (
    SELECT machine_id,
           process_id,
           timestamp -
           LAG(timestamp) OVER (
               PARTITION BY machine_id, process_id
               ORDER BY timestamp
           ) AS process_time
    FROM Activity
) AS t
WHERE process_time IS NOT NULL
GROUP BY machine_id;
```

### Explanation

Instead of joining the table with itself, this solution uses the `LAG()` window function to retrieve the previous timestamp for each process.

#### Step 1: Partition the rows

```sql
PARTITION BY machine_id, process_id
```

This divides the table into separate groups based on each **machine** and **process**.

For example:

| machine_id | process_id |
|------------|------------|
| 0 | 0 |
| 0 | 1 |
| 1 | 0 |
| 1 | 1 |

Each `(machine_id, process_id)` pair is treated as an independent partition.

> **Why is `PARTITION BY` needed?**  
> Without it, `LAG()` would simply return the previous row from the entire table, which could belong to a different machine or process. `PARTITION BY` ensures that `LAG()` only compares rows belonging to the **same process on the same machine**.

#### Step 2: Order each partition

```sql
ORDER BY timestamp
```

Within each partition:

- the **start** record appears first.
- the **end** record appears second.

For example:

| activity_type | timestamp |
|--------------|----------:|
| start | 0.712 |
| end | 1.520 |

#### Step 3: Retrieve the previous timestamp

```sql
LAG(timestamp)
```

creates a new column:

| activity_type | timestamp | previous_timestamp |
|--------------|----------:|-------------------:|
| start | 0.712 | NULL |
| end | 1.520 | 0.712 |

The first row of every partition has no previous row, so `LAG()` returns `NULL`.

#### Step 4: Calculate the processing time

```sql
timestamp - previous_timestamp
```

This gives:

| activity_type | process_time |
|--------------|-------------:|
| start | NULL |
| end | 0.808 |

Only the **end** row contains the actual processing time.

#### Step 5: Remove the `NULL` rows

```sql
WHERE process_time IS NOT NULL
```

The start rows have a `NULL` processing time, so they are removed, leaving one processing time for each process.

#### Step 6: Calculate the average

Finally:

- `GROUP BY machine_id` groups all completed processes for each machine.
- `AVG(process_time)` calculates the average processing time.
- `ROUND(..., 3)` rounds the result to three decimal places.

> **Note:** `LAG()` is a **window function** available in **MySQL 8.0+**, PostgreSQL, SQL Server, Oracle, and other modern SQL databases. It often provides a cleaner and more readable solution than a self join when comparing values from previous rows.
