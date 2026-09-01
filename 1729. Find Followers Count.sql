# 1729. Find Followers Count

> **Difficulty:** Easy

## Problem

For each user, find the number of followers they have.

Return the result table ordered by `user_id` in **ascending order**.

### Table: `Followers`

| Column | Type |
|--------|------|
| user_id | int |
| follower_id | int |

`(user_id, follower_id)` is the primary key, so the same follower cannot follow the same user more than once.

---

## Solution: Using `GROUP BY` and `COUNT()`

```sql
SELECT user_id,
       COUNT(follower_id) AS followers_count
FROM Followers
GROUP BY user_id
ORDER BY user_id;
```

### Explanation

The table contains one row for every follower relationship.

For example:

| user_id | follower_id |
|---------|-------------|
| 0 | 1 |
| 1 | 0 |
| 2 | 0 |
| 2 | 1 |

This means:

```text
User 0 → followed by user 1
User 1 → followed by user 0
User 2 → followed by users 0 and 1
```

We need to count how many followers each `user_id` has.

---

### Step 1: Group by `user_id`

```sql
GROUP BY user_id
```

We group all rows belonging to the same user together.

For example, User 2 has:

| user_id | follower_id |
|---------|-------------|
| 2 | 0 |
| 2 | 1 |

Both rows belong to User 2, so they form one group.

Conceptually:

```text
User 0
└── follower 1

User 1
└── follower 0

User 2
├── follower 0
└── follower 1
```

---

### Step 2: Count the followers

```sql
COUNT(follower_id)
```

Now we count the followers within each `user_id` group.

Therefore:

```text
User 0 → 1 follower
User 1 → 1 follower
User 2 → 2 followers
```

The result becomes:

| user_id | followers_count |
|--------:|----------------:|
| 0 | 1 |
| 1 | 1 |
| 2 | 2 |

---

### Why do we count `follower_id` instead of `user_id`?

We want to count **followers**, not users.

Consider User 2:

| user_id | follower_id |
|---------|-------------|
| 2 | 0 |
| 2 | 1 |

Within this group:

```sql
COUNT(follower_id)
```

counts:

```text
0
1
```

giving:

```text
2
```

which is the number of followers.

`user_id` is simply the value we are grouping by.

---

### `COUNT(follower_id)` vs `COUNT(*)`

We could also write:

```sql
SELECT user_id,
       COUNT(*) AS followers_count
FROM Followers
GROUP BY user_id
ORDER BY user_id;
```

This gives the same result for this problem.

#### `COUNT(*)`

```sql
COUNT(*)
```

counts **every row** in each group.

#### `COUNT(follower_id)`

```sql
COUNT(follower_id)
```

counts only **non-NULL values** of `follower_id`.

Since every row in this problem represents a valid follower relationship, `follower_id` is present, so both produce the same result.

> **Rule to remember:**
>
> ```sql
> COUNT(*)               → counts rows
> COUNT(column)          → counts non-NULL values
> COUNT(DISTINCT column) → counts unique non-NULL values
> ```

---

### Why don't we need `COUNT(DISTINCT follower_id)`?

We could write:

```sql
COUNT(DISTINCT follower_id)
```

but it isn't necessary here.

The primary key is:

```text
(user_id, follower_id)
```

This guarantees that the same follower cannot appear more than once for the same user.

For example, this duplicate relationship is not allowed:

| user_id | follower_id |
|---------|-------------|
| 2 | 0 |
| 2 | 0 |

Therefore:

```sql
COUNT(follower_id)
```

already gives the number of unique followers for each user.

If duplicate relationships were possible, then we would use:

```sql
COUNT(DISTINCT follower_id)
```

---

### Step 3: Sort by `user_id`

```sql
ORDER BY user_id;
```

The problem requires the result to be ordered by `user_id` in ascending order.

`ASC` is the default, so:

```sql
ORDER BY user_id
```

is equivalent to:

```sql
ORDER BY user_id ASC
```

---

## Query Breakdown

The complete query:

```sql
SELECT user_id,
       COUNT(follower_id) AS followers_count
FROM Followers
GROUP BY user_id
ORDER BY user_id;
```

can be read as:

```text
FROM Followers
    ↓
Take the Followers table

GROUP BY user_id
    ↓
Put each user's follower relationships together

COUNT(follower_id)
    ↓
Count how many followers each user has

SELECT user_id, followers_count
    ↓
Return the user and their follower count

ORDER BY user_id
    ↓
Sort users from smallest ID to largest
```

---

## Key Takeaway

This problem follows a very common SQL pattern:

```sql
SELECT group_column,
       COUNT(column)
FROM table
GROUP BY group_column
ORDER BY group_column;
```

Whenever you see:

> **"For each X, find the number of Y"**

think:

```text
GROUP BY X
     ↓
COUNT(Y)
```

For this problem:

```sql
GROUP BY user_id
COUNT(follower_id)
```

The key idea is that **each row represents one follower relationship**, so counting the rows belonging to each user gives the number of followers.
