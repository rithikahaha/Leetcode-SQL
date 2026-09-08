# 196. Delete Duplicate Emails

> **Difficulty:** Easy

## Problem

We are given a `Person` table containing an `id` and an `email`.

Some emails may appear more than once.

We need to **delete all duplicate emails**, while keeping exactly one row for each unique email.

If an email appears multiple times, we must keep the row with the **smallest `id`** and delete all other rows with that email.

### Example

Before:

| id | email                                       |
| -: | ------------------------------------------- |
|  1 | [john@example.com](mailto:john@example.com) |
|  2 | [bob@example.com](mailto:bob@example.com)   |
|  3 | [john@example.com](mailto:john@example.com) |

`john@example.com` appears twice:

```text id="m5x8q2"
id = 1
id = 3
```

We keep:

```text id="v7k3p9"
id = 1
```

and delete:

```text id="c2n6r4"
id = 3
```

### Table: `Person`

| Column  | Type    | Description   |
| ------- | ------- | ------------- |
| `id`    | int     | Primary key   |
| `email` | varchar | Email address |

---

# Solution 1: Self Join + `DELETE`

```sql id="k8m3q1"
DELETE p1
FROM Person p1
JOIN Person p2
    ON p1.email = p2.email
   AND p1.id > p2.id;
```

### Explanation

The key idea is:

> For two rows with the same email, delete the one with the **larger ID**.

We can identify such rows by comparing the table with itself.

---

# Step 1: Create Two References to the Same Table

```sql id="x4p7m2"
FROM Person p1
JOIN Person p2
```

Both `p1` and `p2` refer to the same `Person` table.

This is called a **self join**.

We use two aliases because we need to compare two different rows from the same table.

Think of:

```text id="q9v2k5"
p1 = row we are considering deleting
p2 = row we compare it against
```

---

# Step 2: Find Rows With the Same Email

```sql id="r6m1x8"
ON p1.email = p2.email
```

This makes the join compare rows having the same email.

For the example:

| p1.id | p1.email                                    | p2.id | p2.email                                    |
| ----: | ------------------------------------------- | ----: | ------------------------------------------- |
|     1 | [john@example.com](mailto:john@example.com) |     1 | [john@example.com](mailto:john@example.com) |
|     1 | [john@example.com](mailto:john@example.com) |     3 | [john@example.com](mailto:john@example.com) |
|     3 | [john@example.com](mailto:john@example.com) |     1 | [john@example.com](mailto:john@example.com) |
|     3 | [john@example.com](mailto:john@example.com) |     3 | [john@example.com](mailto:john@example.com) |

We don't actually want a row to compare against itself, so the next condition solves that problem.

---

# Step 3: Find the Row With the Larger ID

```sql id="v3q8m5"
AND p1.id > p2.id
```

This means:

> `p1` has the same email as `p2`, but `p1` has a larger ID.

For:

```text id="7m2x9c"
p1 → id 3 → john@example.com
p2 → id 1 → john@example.com
```

the condition is:

```text id="n5k8q4"
3 > 1 → TRUE
```

So row `3` is identified as a duplicate and can be deleted.

But for:

```text id="b1v6m3"
p1 → id 1
p2 → id 3
```

we get:

```text id="z4q7x9"
1 > 3 → FALSE
```

So row `1` is preserved.

This automatically keeps the smallest ID.

---

# Step 4: Why Does This Keep the Smallest ID?

Suppose an email appears three times:

```text id="m8q3v1"
id | email
---|-----------------
2  | a@example.com
5  | a@example.com
9  | a@example.com
```

For ID `5`:

```text id="p4x7n2"
5 > 2 → TRUE
```

so it gets deleted.

For ID `9`:

```text id="c6m1q8"
9 > 2 → TRUE
9 > 5 → TRUE
```

so it gets deleted.

For ID `2`:

```text id="r9v5k3"
2 > 5 → FALSE
2 > 9 → FALSE
```

so it is never selected for deletion.

Therefore:

```text id="w2m7x4"
smallest ID → kept
larger IDs   → deleted
```

---

# Step 5: Why `DELETE p1`?

The query starts with:

```sql id="f8q2m6"
DELETE p1
```

This tells MySQL:

> Delete the rows represented by the `p1` alias.

The joined `p2` rows are only being used to determine **which `p1` rows are duplicates**.

So conceptually:

```text id="s4x8n1"
p1 → candidate for deletion
p2 → row used for comparison
```

---

# Why Can't We Just Use `DELETE WHERE email IN (...)`?

A query such as:

```sql id="d7m2q9"
DELETE FROM Person
WHERE email IN (
    SELECT email
    FROM Person
    GROUP BY email
    HAVING COUNT(*) > 1
);
```

would be wrong.

Why?

Because it would delete **every row** belonging to a duplicated email.

For:

```text id="g5v1x8"
1 | john@example.com
3 | john@example.com
```

both rows would satisfy the condition.

But we only want to delete:

```text id="c9m4q2"
id = 3
```

and keep:

```text id="k6x2p7"
id = 1
```

So we need to compare IDs, not just detect duplicate emails.

---

# Solution 2: `DELETE` with `EXISTS`

Another way is to use a correlated `EXISTS` subquery.

```sql id="n3q8v5"
DELETE FROM Person
WHERE EXISTS (
    SELECT 1
    FROM Person p2
    WHERE Person.email = p2.email
      AND Person.id > p2.id
);
```

### Explanation

For each row in `Person`, we ask:

> Does another row exist with the same email and a smaller ID?

If yes, the current row is a duplicate and should be deleted.

---

## Understanding the `EXISTS` Condition

```sql id="t7m2x9"
EXISTS (
    SELECT 1
    FROM Person p2
    WHERE Person.email = p2.email
      AND Person.id > p2.id
)
```

The important conditions are:

```sql id="v4q8k1"
Person.email = p2.email
```

and:

```sql id="m6x3p9"
Person.id > p2.id
```

Together they mean:

> There is another person with the same email whose ID is smaller than this row's ID.

If that is true, delete the current row.

---

# Example With Three Duplicate Rows

Suppose:

| id | email                                 |
| -: | ------------------------------------- |
|  2 | [a@example.com](mailto:a@example.com) |
|  5 | [a@example.com](mailto:a@example.com) |
|  9 | [a@example.com](mailto:a@example.com) |

### Check ID 2

Is there someone with:

```text id="c8m1q4"
same email
AND id < 2?
```

No.

So ID `2` stays.

### Check ID 5

Is there someone with:

```text id="p7x3v9"
same email
AND id < 5?
```

Yes:

```text id="r4k8m2"
ID 2
```

So ID `5` is deleted.

### Check ID 9

Is there someone with:

```text id="w6q2n5"
same email
AND id < 9?
```

Yes:

```text id="z1m7c4"
ID 2
ID 5
```

So ID `9` is deleted.

Final result:

```text id="h3v8q1"
2 | a@example.com
```

---

# Comparing the Two Solutions

## Self Join

```sql id="q5m9x2"
DELETE p1
FROM Person p1
JOIN Person p2
    ON p1.email = p2.email
   AND p1.id > p2.id;
```

Think:

> Find two rows with the same email. If `p1` has the larger ID, delete `p1`.

## `EXISTS`

```sql id="r8k3v6"
DELETE FROM Person
WHERE EXISTS (
    SELECT 1
    FROM Person p2
    WHERE Person.email = p2.email
      AND Person.id > p2.id
);
```

Think:

> Delete this row if another row with the same email and a smaller ID exists.

Both express the same logic.

For this problem, the **self-join solution is probably the easiest to remember**.

---

# Important Concept: `DELETE` vs `SELECT`

This problem explicitly asks for a `DELETE` statement.

Most LeetCode SQL problems ask you to **return a result**, so we normally use:

```sql id="x6m2q9"
SELECT
```

But here the task is to actually remove rows from the table.

Therefore we need:

```sql id="p4v8k1"
DELETE
```

The driver will then display the modified `Person` table.

---

# Important Concept: Self Join

A self join means joining a table to itself.

Normally we might write:

```sql id="j7m3x8"
Employee e
JOIN Department d
```

where two different tables are involved.

Here:

```sql id="q2v9c5"
Person p1
JOIN Person p2
```

both references point to the same table.

We do this when we need to compare rows **against other rows in the same table**.

Common use cases include:

* Finding duplicate rows
* Finding employees with the same manager
* Comparing current and previous records
* Finding rows with greater/smaller values than another row
* Detecting relationships within the same table

---

# Important Concept: `p1.id > p2.id`

This single condition solves the "keep the smallest ID" requirement.

```sql id="m8x4q1"
p1.id > p2.id
```

means:

> `p1` is the row with the larger ID.

Therefore, `p1` is the row we delete.

The smallest ID has no smaller duplicate ID to compare against, so it survives.

This is a very useful duplicate-removal pattern:

```text id="v6n2k9"
Same identifying value
        +
Larger ID
        ↓
Duplicate row
        ↓
DELETE
```

---

# Why the Primary Key Matters

The problem guarantees:

```text id="z5q8m3"
id is the primary key
```

Therefore every row has a unique ID.

This allows us to reliably decide which duplicate row should survive:

```text id="k2x7p4"
smallest ID → keep
larger ID   → delete
```

The email itself does not have to be unique because duplicate emails are exactly what we're trying to remove.

---

# Key Takeaway

The most important pattern to remember is:

```sql id="c9m4x7"
DELETE p1
FROM Person p1
JOIN Person p2
    ON p1.email = p2.email
   AND p1.id > p2.id;
```

Think about it in plain English:

> **Find two rows with the same email. If one row has a larger ID than the other, delete the larger-ID row.**

The logic is:

```text id="q7v3m1"
Same email?
    ↓
Yes
    ↓
Compare IDs
    ↓
Larger ID?
    ↓
Delete it
    ↓
Smallest ID remains
```

The key SQL concepts from this problem are:

```text id="x5k9p2"
SELF JOIN
    → compare rows within the same table

p1.email = p2.email
    → identify duplicates

p1.id > p2.id
    → identify the duplicate with the larger ID

DELETE p1
    → remove the duplicate row
```

And the general rule to remember is:

> **To delete duplicates while keeping the smallest ID, self-join on the duplicate-defining column and delete the row whose ID is greater than another matching row's ID.**
