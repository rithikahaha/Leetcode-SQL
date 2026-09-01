# 550. Game Play Analysis IV

> **Difficulty:** Medium

## Problem

Find the **fraction of players** who logged in again on the day immediately after their **first login**.

The fraction is calculated as:

```text
Number of players who logged in the next day
------------------------------------------------
Total number of players
```

Round the result to **2 decimal places**.

### Table: Activity

| Column | Type |
|--------|------|
| player_id | int |
| device_id | int |
| event_date | date |
| games_played | int |

---

## Solution 1: Using `MIN()` and `EXISTS`

```sql
SELECT ROUND(
           COUNT(DISTINCT a.player_id) /
           (SELECT COUNT(DISTINCT player_id) FROM Activity),
           2
       ) AS fraction
FROM Activity a
WHERE EXISTS (
    SELECT 1
    FROM Activity b
    WHERE b.player_id = a.player_id
      AND b.event_date = DATE_ADD(a.event_date, INTERVAL 1 DAY)
      AND a.event_date = (
          SELECT MIN(event_date)
          FROM Activity
          WHERE player_id = a.player_id
      )
);
```

### Explanation

The main challenge is identifying players who logged in **exactly one day after their first login**.

#### Step 1: Find each player's first login

```sql
SELECT MIN(event_date)
FROM Activity
WHERE player_id = a.player_id
```

`MIN(event_date)` returns the earliest login date for that player.

For example:

| player_id | event_date |
|-----------|------------|
| 1 | 2016-03-01 |
| 1 | 2016-03-02 |
| 2 | 2017-06-25 |
| 3 | 2016-03-02 |
| 3 | 2018-07-03 |

The first login dates are:

| player_id | first_login |
|-----------|-------------|
| 1 | 2016-03-01 |
| 2 | 2017-06-25 |
| 3 | 2016-03-02 |

The condition:

```sql
a.event_date = (
    SELECT MIN(event_date)
    ...
)
```

ensures that `a` represents the player's **first login**.

---

#### Step 2: Check whether the player logged in the next day

```sql
b.event_date = DATE_ADD(a.event_date, INTERVAL 1 DAY)
```

This checks whether there is another activity record exactly **one day after** the first login.

For player 1:

```text
First login:  2016-03-01
Next day:     2016-03-02
```

So player 1 qualifies.

For player 3:

```text
First login:  2016-03-02
Next day:     2016-03-03
```

There is no activity on March 3, so player 3 does not qualify.

---

#### Step 3: Use `EXISTS`

```sql
WHERE EXISTS (
    SELECT 1
    FROM Activity b
    ...
)
```

`EXISTS` checks whether **at least one matching row** exists.

We don't actually need any data from `b`; we only need to know whether a matching login exists.

Therefore:

```sql
SELECT 1
```

is conventionally used inside `EXISTS`.

> **Note:** `EXISTS` is useful when the question is essentially **"Does a matching row exist?"** It stops looking once it finds a match and does not create duplicate rows like a normal join can.

---

#### Step 4: Count the qualifying players

```sql
COUNT(DISTINCT a.player_id)
```

counts the number of players who logged in the following day.

`DISTINCT` ensures that each qualifying player is counted only once.

For the example:

```text
Qualifying players = 1
```

---

#### Step 5: Count total players

```sql
SELECT COUNT(DISTINCT player_id)
FROM Activity
```

counts all unique players.

For the example:

```text
Total players = 3
```

---

#### Step 6: Calculate the fraction

```sql
COUNT(DISTINCT a.player_id) /
(SELECT COUNT(DISTINCT player_id) FROM Activity)
```

For the example:

```text
1 / 3 = 0.3333...
```

Finally:

```sql
ROUND(..., 2)
```

returns:

```text
0.33
```

---

## Solution 2: Using `MIN()` and Self Join

```sql
SELECT ROUND(
           COUNT(DISTINCT a.player_id) /
           (SELECT COUNT(DISTINCT player_id) FROM Activity),
           2
       ) AS fraction
FROM Activity a
JOIN (
    SELECT player_id,
           MIN(event_date) AS first_date
    FROM Activity
    GROUP BY player_id
) f
ON a.player_id = f.player_id
AND a.event_date = DATE_ADD(f.first_date, INTERVAL 1 DAY);
```

### Explanation

This solution first finds each player's first login date and then checks whether the player has an activity record on the following day.

#### Step 1: Find the first login for every player

```sql
SELECT player_id,
       MIN(event_date) AS first_date
FROM Activity
GROUP BY player_id
```

This produces one row per player containing their earliest login date.

For example:

| player_id | first_date |
|-----------|------------|
| 1 | 2016-03-01 |
| 2 | 2017-06-25 |
| 3 | 2016-03-02 |

---

#### Step 2: Find activity one day after the first login

```sql
ON a.player_id = f.player_id
AND a.event_date = DATE_ADD(f.first_date, INTERVAL 1 DAY)
```

The join matches a player's activity with the date immediately after their first login.

For player 1:

```text
first_date = 2016-03-01
DATE_ADD(first_date, INTERVAL 1 DAY)
             ↓
          2016-03-02
```

An activity record exists on that date, so player 1 qualifies.

---

#### Step 3: Count qualifying players

```sql
COUNT(DISTINCT a.player_id)
```

counts the players who have activity on the day after their first login.

---

#### Step 4: Divide by total players

```sql
COUNT(DISTINCT a.player_id) /
(SELECT COUNT(DISTINCT player_id) FROM Activity)
```

calculates the required fraction.

Finally, `ROUND(..., 2)` rounds it to two decimal places.

> **Note:** The subquery finds the **first login date**, while the outer query checks for an activity record exactly one day later. This is a common SQL pattern for problems involving **"first occurrence + subsequent event."**

---

## Solution 3: Using `ROW_NUMBER()`

```sql
SELECT ROUND(
           SUM(next_date IS NOT NULL) / COUNT(*),
           2
       ) AS fraction
FROM (
    SELECT player_id,
           event_date,
           LEAD(event_date) OVER (
               PARTITION BY player_id
               ORDER BY event_date
           ) AS next_date,
           ROW_NUMBER() OVER (
               PARTITION BY player_id
               ORDER BY event_date
           ) AS rn
    FROM Activity
) a
WHERE rn = 1
  AND next_date = DATE_ADD(event_date, INTERVAL 1 DAY);
```

### Explanation

This solution uses window functions to identify each player's first login and check the following activity date.

However, there is an important issue with the query above: because of the condition:

```sql
WHERE rn = 1
AND next_date = DATE_ADD(event_date, INTERVAL 1 DAY)
```

players who **did not** log in the next day are removed before the final `COUNT(*)`.

Therefore, the denominator would incorrectly count only qualifying players.

A correct window-function solution is:

```sql
SELECT ROUND(
           AVG(next_date = DATE_ADD(first_date, INTERVAL 1 DAY)),
           2
       ) AS fraction
FROM (
    SELECT player_id,
           event_date,
           MIN(event_date) OVER (
               PARTITION BY player_id
           ) AS first_date,
           LEAD(event_date) OVER (
               PARTITION BY player_id
               ORDER BY event_date
           ) AS next_date
    FROM Activity
) a
WHERE event_date = first_date;
```

### Explanation

This version keeps **every player's first login**, whether or not they returned the next day.

#### Step 1: Find the first login using `MIN()`

```sql
MIN(event_date) OVER (
    PARTITION BY player_id
) AS first_date
```

Unlike regular `MIN()` with `GROUP BY`, this is a **window function**, so it keeps every activity row while adding the player's first login date as a new column.

For example:

| player_id | event_date | first_date |
|-----------|------------|------------|
| 1 | 2016-03-01 | 2016-03-01 |
| 1 | 2016-03-02 | 2016-03-01 |
| 2 | 2017-06-25 | 2017-06-25 |
| 3 | 2016-03-02 | 2016-03-02 |
| 3 | 2018-07-03 | 2016-03-02 |

---

#### Step 2: Find the next login

```sql
LEAD(event_date) OVER (
    PARTITION BY player_id
    ORDER BY event_date
) AS next_date
```

`LEAD()` retrieves the date from the **next row** for the same player.

For player 1:

| event_date | next_date |
|------------|-----------|
| 2016-03-01 | 2016-03-02 |
| 2016-03-02 | NULL |

---

#### Step 3: Keep only first-login rows

```sql
WHERE event_date = first_date
```

Now there is exactly one row per player.

The resulting data looks like:

| player_id | first_date | next_date |
|-----------|------------|-----------|
| 1 | 2016-03-01 | 2016-03-02 |
| 2 | 2017-06-25 | NULL |
| 3 | 2016-03-02 | NULL |

---

#### Step 4: Check whether the next login was exactly one day later

```sql
next_date = DATE_ADD(first_date, INTERVAL 1 DAY)
```

This produces:

| player_id | returned next day? |
|-----------|-------------------:|
| 1 | 1 |
| 2 | 0 |
| 3 | 0 |

Since MySQL treats `TRUE` as `1` and `FALSE` as `0`:

```sql
AVG(next_date = DATE_ADD(first_date, INTERVAL 1 DAY))
```

calculates the fraction directly.

For the example:

```text
(1 + 0 + 0) / 3
= 0.3333...
```

which becomes:

```text
0.33
```

> **Note:** This is a good example of the **"one row per entity → evaluate a condition → `AVG()`"** pattern. `AVG(boolean_condition)` works because the condition evaluates to `1` or `0` in MySQL.

> **Note:** `LEAD()` is useful here because we want to compare each player's **first login with their next recorded login**. We still check the actual date difference because the next recorded login is not necessarily the next calendar day.
