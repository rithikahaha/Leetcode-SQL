# 1141. User Activity for the Past 30 Days I

> **Difficulty:** Easy

## Problem

Find the **daily active user count** for the 30-day period ending on **2019-07-27**, inclusively.

A user is considered **active on a day** if they performed at least one activity on that day.

Any activity type counts as valid activity.

Return the result table in **any order**.

### Table: Activity

| Column | Type |
|--------|------|
| user_id | int |
| session_id | int |
| activity_date | date |
| activity_type | enum |

---

## Solution 1: Using `COUNT(DISTINCT)`

```sql
SELECT activity_date AS day,
       COUNT(DISTINCT user_id) AS active_users
FROM Activity
WHERE activity_date BETWEEN '2019-06-28' AND '2019-07-27'
GROUP BY activity_date;
```

### Explanation

The problem asks for the number of **unique users active on each day** during a specific 30-day period.

The key concepts are:

- Filter the dates using `BETWEEN`.
- Group the activities by date.
- Count unique users using `COUNT(DISTINCT user_id)`.

---

### Step 1: Filter the 30-day period

```sql
WHERE activity_date BETWEEN '2019-06-28' AND '2019-07-27'
```

The period ends on:

```text
2019-07-27
```

and is **30 days inclusive**.

Therefore, the starting date is:

```text
2019-06-28
```

So we keep activities from:

```text
2019-06-28 → 2019-07-27
```

`BETWEEN` is inclusive of both boundaries.

> **Important:** Since the problem says the period ends on July 27 **inclusively**, July 27 must be included in the result.

---

### Step 2: Group activities by day

```sql
GROUP BY activity_date
```

This creates one group for every date on which activity occurred.

For example:

| activity_date | user_id |
|----------------|--------:|
| 2019-07-20 | 1 |
| 2019-07-20 | 1 |
| 2019-07-20 | 2 |
| 2019-07-21 | 2 |
| 2019-07-21 | 3 |
| 2019-07-21 | 3 |

The rows are grouped separately for:

```text
2019-07-20
2019-07-21
```

---

### Step 3: Count unique users

```sql
COUNT(DISTINCT user_id)
```

This counts each user **only once per day**, even if they performed multiple activities.

For example, on `2019-07-20`:

| user_id | activity |
|--------:|----------|
| 1 | open_session |
| 1 | scroll_down |
| 1 | end_session |
| 2 | open_session |

There are 4 activity records, but only **2 unique users**.

Therefore:

```sql
COUNT(DISTINCT user_id) = 2
```

This is why we cannot simply use:

```sql
COUNT(user_id)
```

because that would count activities rather than users.

---

### Step 4: Return the date as `day`

```sql
activity_date AS day
```

The problem expects the output column to be called `day`, so we use an alias.

---

## Why don't we filter `activity_type`?

The problem explicitly states that **any activity** counts as valid activity.

The four possible activity types are:

```text
open_session
end_session
scroll_down
send_message
```

Therefore, there is no need for something like:

```sql
WHERE activity_type IN (...)
```

Every activity already qualifies a user as active.

---

## Why don't we show days with zero active users?

The problem says:

> We do not care about days with zero active users.

Our query only creates groups for dates that actually exist in the `Activity` table.

Therefore, dates with no activity automatically do not appear in the result.

For example, if there were no activity on:

```text
2019-07-19
```

there would simply be no `2019-07-19` group.

No additional filtering is necessary.

---

## Solution 2: Using `>=` and `<=`

```sql
SELECT activity_date AS day,
       COUNT(DISTINCT user_id) AS active_users
FROM Activity
WHERE activity_date >= '2019-06-28'
  AND activity_date <= '2019-07-27'
GROUP BY activity_date;
```

### Explanation

This solution is logically identical to Solution 1.

Instead of:

```sql
BETWEEN '2019-06-28' AND '2019-07-27'
```

we explicitly write:

```sql
activity_date >= '2019-06-28'
AND activity_date <= '2019-07-27'
```

Both conditions include the starting and ending dates.

So:

```sql
BETWEEN start_date AND end_date
```

is equivalent to:

```sql
>= start_date
AND <= end_date
```

for this date column.

> **Note:** Writing the conditions separately can sometimes make the inclusiveness of the date boundaries more obvious when you're reading the query.

---

## Key Takeaways

### 1. "Active users" usually means `COUNT(DISTINCT user_id)`

If a user can perform multiple activities:

```sql
COUNT(user_id)
```

counts **activities**.

Whereas:

```sql
COUNT(DISTINCT user_id)
```

counts **unique users**.

---

### 2. "Per day" means `GROUP BY date`

Whenever a problem asks:

> "Find X for each day"

think:

```sql
GROUP BY date_column
```

---

### 3. Fixed date range

For a specific inclusive date range, you can use:

```sql
WHERE date_column BETWEEN start_date AND end_date
```

or:

```sql
WHERE date_column >= start_date
  AND date_column <= end_date
```

---

### Final Pattern

This problem follows a very common SQL pattern:

```sql
SELECT date_column,
       COUNT(DISTINCT user_id)
FROM table
WHERE date_column BETWEEN start_date AND end_date
GROUP BY date_column;
```

Whenever you see:

> **"How many unique users did X on each day?"**

this is a pattern worth recognizing immediately.
