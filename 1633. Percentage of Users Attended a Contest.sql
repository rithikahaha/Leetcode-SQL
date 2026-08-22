# 1633. Percentage of Users Attended a Contest

> **Difficulty:** Easy

## Problem

Find the percentage of users who registered for each contest.

The percentage is calculated as:

```
Number of users registered for the contest
------------------------------------------ × 100
Total number of users
```

Round the percentage to **2 decimal places**.

Return the result table ordered by:

1. `percentage` in **descending** order.
2. `contest_id` in **ascending** order if percentages are equal.

### Table: Users

| Column | Type |
|--------|------|
| user_id | int |
| user_name | varchar |

### Table: Register

| Column | Type |
|--------|------|
| contest_id | int |
| user_id | int |

---

## Solution 1: Using `COUNT()` and a Subquery

```sql
SELECT r.contest_id,
       ROUND(
           COUNT(r.user_id) * 100.0 /
           (SELECT COUNT(*) FROM Users),
           2
       ) AS percentage
FROM Register r
GROUP BY r.contest_id
ORDER BY percentage DESC,
         contest_id ASC;
```

### Explanation

This is the simplest and most efficient solution.

#### Step 1: Count the number of registered users

```sql
COUNT(r.user_id)
```

Since `(contest_id, user_id)` is the primary key of the `Register` table, a user can register for the same contest only once.

Therefore:

```sql
COUNT(r.user_id)
```

returns the number of users registered for each contest.

#### Step 2: Count the total number of users

```sql
(SELECT COUNT(*) FROM Users)
```

The subquery returns the total number of users in the system.

For example:

| user_id |
|---------|
| 2 |
| 6 |
| 7 |

```
COUNT(*) = 3
```

#### Step 3: Calculate the percentage

```sql
COUNT(r.user_id) * 100.0 /
(SELECT COUNT(*) FROM Users)
```

For example:

Contest **215**

```
2 / 3 × 100 = 66.67
```

Contest **207**

```
1 / 3 × 100 = 33.33
```

Multiplying by `100.0` ensures the calculation is performed using decimal arithmetic instead of integer division.

#### Step 4: Round the result

```sql
ROUND(..., 2)
```

rounds the percentage to two decimal places.

#### Step 5: Sort the output

```sql
ORDER BY percentage DESC,
         contest_id ASC
```

- Higher percentages appear first.
- If two contests have the same percentage, the smaller `contest_id` appears first.

> **Note:** This is the preferred solution because it scans the `Users` table only once and avoids generating unnecessary rows.

---

## Solution 2: Using `CROSS JOIN`

```sql
SELECT r.contest_id,
       ROUND(
           COUNT(DISTINCT r.user_id) * 100.0 /
           COUNT(DISTINCT u.user_id),
           2
       ) AS percentage
FROM Users u
CROSS JOIN Register r
GROUP BY r.contest_id
ORDER BY percentage DESC,
         contest_id ASC;
```

### Explanation

This solution uses a `CROSS JOIN` to combine every user with every registration.

#### Step 1: Create all combinations

```sql
Users
CROSS JOIN
Register
```

A `CROSS JOIN` produces the Cartesian product of both tables.

If there are:

- **3 users**
- **12 registration records**

the result contains:

```
3 × 12 = 36 rows
```

Each registration is paired with every user.

---

#### Step 2: Count the registered users

```sql
COUNT(DISTINCT r.user_id)
```

Because the `CROSS JOIN` duplicates every registration once for each user, using `DISTINCT` removes those duplicates.

This gives the number of unique users registered for each contest.

For example:

Contest **215**

| Registered Users |
|------------------|
| 6 |
| 7 |

```
COUNT(DISTINCT r.user_id) = 2
```

---

#### Step 3: Count the total users

```sql
COUNT(DISTINCT u.user_id)
```

Even though every user appears many times after the `CROSS JOIN`, `DISTINCT` ensures each user is counted only once.

For example:

| Users |
|--------|
| 2 |
| 6 |
| 7 |

```
COUNT(DISTINCT u.user_id) = 3
```

---

#### Step 4: Calculate the percentage

```sql
COUNT(DISTINCT r.user_id) * 100.0 /
COUNT(DISTINCT u.user_id)
```

For contest **215**:

```
2 / 3 × 100 = 66.67
```

Finally,

```sql
ROUND(..., 2)
```

rounds the percentage to two decimal places.

---

#### Step 5: Sort the result

```sql
ORDER BY percentage DESC,
         contest_id ASC
```

returns the contests in the required order.

> **Note:** Although this solution produces the correct result, it is **not recommended** in practice. The `CROSS JOIN` creates a large Cartesian product (every user paired with every registration), generating many unnecessary rows. The use of `COUNT(DISTINCT ...)` removes the duplicate counts, but the extra rows still make the query much less efficient than the standard solution. This approach is included mainly to demonstrate how a `CROSS JOIN` works, not because it is the optimal solution.
