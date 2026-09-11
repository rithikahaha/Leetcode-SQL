# 602. Friend Requests II: Who Has the Most Friends

> **Difficulty:** Medium

## Problem

We are given a `RequestAccepted` table containing friendship relationships.

Each row represents a successfully accepted friend request:

* `requester_id` = person who sent the request
* `accepter_id` = person who accepted the request

We need to find the person who has the **most friends** and return:

* `id` → the person's ID
* `num` → their total number of friends

The test cases guarantee that **only one person has the maximum number of friends**.

### Table: `RequestAccepted`

| Column         | Type | Description                               |
| -------------- | ---- | ----------------------------------------- |
| `requester_id` | int  | ID of the person who sent the request     |
| `accepter_id`  | int  | ID of the person who accepted the request |
| `accept_date`  | date | Date the request was accepted             |

The primary key is:

(requester_id, accepter_id)

This means the same pair of people cannot appear more than once.


# Solution 1: `UNION ALL` + `GROUP BY` + `ORDER BY`

SELECT id, COUNT(*) AS num
FROM (
    SELECT requester_id AS id
    FROM RequestAccepted

    UNION ALL

    SELECT accepter_id AS id
    FROM RequestAccepted
) friends
GROUP BY id
ORDER BY num DESC
LIMIT 1;

### Explanation

The main challenge in this problem is that a person's ID can appear in **two different columns**.

For example:

requester_id = 1
accepter_id = 3

means:

```text
1 and 3 are friends
```

So:

* `1` needs to receive one friend count.
* `3` also needs to receive one friend count.

If we only count `requester_id`, we would miss friendships for people appearing only as `accepter_id`.

That's why we combine both columns first.

---

## Step 1: Get All Requesters

```sql id="f7j9yz"
SELECT requester_id AS id
FROM RequestAccepted
```

From the example:

| requester_id |
| -----------: |
|            1 |
|            1 |
|            2 |
|            3 |

We rename it:

```sql id="1svh9b"
requester_id AS id
```

because eventually we want one column called `id`.

---

## Step 2: Get All Accepters

```sql id="wmr2h1"
SELECT accepter_id AS id
FROM RequestAccepted
```

This gives:

| id |
| -: |
|  2 |
|  3 |
|  3 |
|  4 |

Now we have both sides of every friendship.

---

# Step 3: Combine the Two Columns

We use:

```sql id="7c7ywt"
UNION ALL
```

So:

```sql id="q9b1p7"
SELECT requester_id AS id
FROM RequestAccepted

UNION ALL

SELECT accepter_id AS id
FROM RequestAccepted
```

produces:

| id |
| -: |
|  1 |
|  1 |
|  2 |
|  3 |
|  2 |
|  3 |
|  3 |
|  4 |

This is the key idea of the entire problem.

Every accepted friendship contributes:

```text id="uw9i8u"
1 occurrence to requester
1 occurrence to accepter
```

Therefore, counting the occurrences of each ID gives the person's total number of friends.

---

# Step 4: Why `UNION ALL` Instead of `UNION`?

This is extremely important.

We use:

```sql id="xmbf5y"
UNION ALL
```

rather than:

```sql id="6yq7fz"
UNION
```

because we **need duplicates**.

For example, person `3` appears three times:

```text id="q1g6cm"
3
3
3
```

Those three occurrences represent three different friendships:

```text id="3xk9oe"
3 ↔ 1
3 ↔ 2
3 ↔ 4
```

If we used `UNION`, duplicate IDs would be removed:

```text id="0h2vsi"
3
```

and we would incorrectly conclude that person `3` has only one friend.

So:

> **Use `UNION ALL` when duplicate rows carry meaningful information and should be counted.**

---

# Step 5: Group by Person

Now we have one column containing every person's occurrence.

We write:

```sql id="b9m4is"
GROUP BY id
```

This creates one group for each person.

The data:

```text id="g5lqpr"
1
1
2
3
2
3
3
4
```

becomes conceptually:

```text id="4s6y0g"
Person 1 → 2 occurrences
Person 2 → 2 occurrences
Person 3 → 3 occurrences
Person 4 → 1 occurrence
```

---

# Step 6: Count the Friends

```sql id="k6ib6t"
COUNT(*) AS num
```

Since every occurrence represents one friendship, the number of occurrences is the number of friends.

So:

| id | num |
| -: | --: |
|  1 |   2 |
|  2 |   2 |
|  3 |   3 |
|  4 |   1 |

Person `3` has the highest count.

---

# Step 7: Find the Person With the Most Friends

We sort by the friend count:

```sql id="52o5cw"
ORDER BY num DESC
```

This produces:

| id | num |
| -: | --: |
|  3 |   3 |
|  1 |   2 |
|  2 |   2 |
|  4 |   1 |

Then:

```sql id="by8ygl"
LIMIT 1
```

keeps only:

```text id="13s4xv"
3 | 3
```

which is the required answer.

---

# Why This Approach Works

Consider one friendship:

```text id="h4fd70"
1 → 3
```

This creates:

```text id="j2oc41"
requester_id = 1
accepter_id = 3
```

After the `UNION ALL`, we have:

```text id="u1av9s"
1
3
```

Therefore:

* Person `1` gets one friend.
* Person `3` gets one friend.

This happens for every friendship.

So after combining both columns and counting occurrences, we automatically get the total number of friends for every person.

---

# Solution 2: `UNION ALL` + `MAX()`

We can also find the maximum friend count using an additional aggregation step.

```sql id="c5k1dw"
SELECT id, COUNT(*) AS num
FROM (
    SELECT requester_id AS id
    FROM RequestAccepted

    UNION ALL

    SELECT accepter_id AS id
    FROM RequestAccepted
) friends
GROUP BY id
HAVING COUNT(*) = (
    SELECT MAX(num)
    FROM (
        SELECT COUNT(*) AS num
        FROM (
            SELECT requester_id AS id
            FROM RequestAccepted

            UNION ALL

            SELECT accepter_id AS id
            FROM RequestAccepted
        ) all_friends
        GROUP BY id
    ) counts
);
```

Because the problem guarantees only one person has the maximum, this returns one row.

However, this is much more complicated than necessary.

For this problem, the first solution:

```sql id="1jvknn"
ORDER BY num DESC
LIMIT 1
```

is much easier to read.

---

# Follow-Up: What If Multiple People Can Have the Same Maximum?

The original problem guarantees that only one person has the most friends.

But the follow-up asks:

> What if multiple people have the same maximum number of friends?

Then we should **not** use:

```sql id="k9q6qm"
LIMIT 1
```

because `LIMIT 1` would arbitrarily return only one of the tied people.

Instead, we can use `RANK()`.

```sql id="zqk1fu"
SELECT id, num
FROM (
    SELECT
        id,
        COUNT(*) AS num,
        RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
    FROM (
        SELECT requester_id AS id
        FROM RequestAccepted

        UNION ALL

        SELECT accepter_id AS id
        FROM RequestAccepted
    ) friends
    GROUP BY id
) ranked
WHERE rnk = 1;
```

### Why `RANK()`?

Suppose the counts are:

| id | num |
| -: | --: |
|  3 |   3 |
|  5 |   3 |
|  1 |   2 |
|  2 |   1 |

With:

```sql id="kh7gcy"
RANK() OVER (ORDER BY COUNT(*) DESC)
```

we get:

| id | num | rnk |
| -: | --: | --: |
|  3 |   3 |   1 |
|  5 |   3 |   1 |
|  1 |   2 |   3 |
|  2 |   1 |   4 |

Then:

```sql id="jibc6y"
WHERE rnk = 1
```

returns **both** people with the maximum number of friends.

This is a useful pattern whenever a problem says:

> Find all rows with the highest/lowest value.

---

# Important Concept: Two Columns Represent One Relationship

This is the main trick in this problem.

The table represents a relationship:

```text
requester_id ↔ accepter_id
```

Both people are friends.

Therefore, neither column alone contains the complete information about someone's number of friends.

We need to turn:

```text id="5k3c6u"
requester_id | accepter_id
-------------+------------
1            | 2
1            | 3
2            | 3
3            | 4
```

into:

```text id="m9m5t0"
id
--
1
1
2
3
2
3
3
4
```

Then we can simply:

```sql id="yq7m8j"
GROUP BY id
```

and:

```sql id="1l8hbb"
COUNT(*)
```

---

# Important Concept: Why `COUNT(*)` Works

After the `UNION ALL`, every row represents one friendship involving that person.

For example:

```text id="e8ckdw"
3
3
3
```

means person `3` participated in three accepted friendships.

Therefore:

```sql id="g4b9f8"
COUNT(*)
```

is exactly the number of friends.

We don't need:

```sql id="ry5h4r"
COUNT(DISTINCT id)
```

because that would always count only one value inside each group.

We also don't need `DISTINCT` because the same person's repeated occurrences are **supposed** to be counted.

---

# Important Concept: `UNION` vs `UNION ALL`

Remember the difference:

### `UNION`

Removes duplicate rows.

```text id="n8x6j1"
1
1
2
3
```

becomes:

```text id="qv3v7x"
1
2
3
```

### `UNION ALL`

Keeps duplicates.

```text id="8vwr4g"
1
1
2
3
```

stays:

```text id="j9k9x4"
1
1
2
3
```

When you're trying to **count occurrences**, `UNION ALL` is usually what you want.

---

# Important Concept: `ORDER BY ... DESC LIMIT 1`

Another reusable pattern is:

```sql id="k7o7fq"
ORDER BY num DESC
LIMIT 1
```

This means:

1. Sort the results from largest `num` to smallest.
2. Take the first row.

It is a simple way to find the maximum row when the problem guarantees that only one answer exists.

If ties are possible and **all tied rows** are required, use a ranking approach such as:

```sql id="oh5v6d"
RANK() OVER (ORDER BY num DESC)
```

and then:

```sql id="q9zvjt"
WHERE rnk = 1
```

---

# Key Takeaway

The most important idea in this problem is:

> **When a relationship is represented by two columns and both sides need to be counted, combine the two columns into one list using `UNION ALL`, then group and count.**

The general pattern is:

```sql id="8l8n8m"
SELECT id, COUNT(*) AS num
FROM (
    SELECT requester_id AS id
    FROM RequestAccepted

    UNION ALL

    SELECT accepter_id AS id
    FROM RequestAccepted
) friends
GROUP BY id
ORDER BY num DESC
LIMIT 1;
```

Think of the process as:

```text id="bhgrd1"
requester_id ──┐
               ├──→ UNION ALL → one ID column → GROUP BY → COUNT
accepter_id ───┘
```

And remember:

```text id="1m0q72"
UNION      → removes duplicates
UNION ALL  → keeps duplicates
```

For this problem, **keeping duplicates is essential**, because every occurrence represents another friendship.
