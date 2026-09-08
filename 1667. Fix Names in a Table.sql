# 1667. Fix Names in a Table

> **Difficulty:** Easy

## Problem

We are given a `Users` table containing user IDs and names.

The names can contain a mixture of uppercase and lowercase letters.

We need to fix every name so that:

* The **first character is uppercase**.
* Every character **after the first character is lowercase**.
* The result must be ordered by `user_id`.

For example:

```text
aLice → Alice
bOB   → Bob
```

### Table: `Users`

| Column    | Type    | Description          |
| --------- | ------- | -------------------- |
| `user_id` | int     | User ID; primary key |
| `name`    | varchar | User's name          |

---

# Solution 1: `UPPER()` + `LOWER()` + `LEFT()` + `SUBSTRING()`

```sql id="8k3m1q"
SELECT
    user_id,
    CONCAT(
        UPPER(LEFT(name, 1)),
        LOWER(SUBSTRING(name, 2))
    ) AS name
FROM Users
ORDER BY user_id;
```

### Explanation

The goal is to transform:

```text id="5q7v2n"
aLice
```

into:

```text id="p8x4m1"
Alice
```

We can break the name into two parts:

```text id="c6k9r3"
First character  → uppercase
Remaining chars  → lowercase
```

Then we combine the two parts.

---

# Step 1: Get the First Character

```sql id="m4x8p2"
LEFT(name, 1)
```

`LEFT()` returns a specified number of characters from the beginning of a string.

For example:

```text id="r7q1v5"
LEFT('aLice', 1) → 'a'
LEFT('bOB', 1)   → 'b'
```

So:

```sql id="w3n6k9"
LEFT(name, 1)
```

extracts the first character.

---

# Step 2: Convert the First Character to Uppercase

We wrap it with:

```sql id="q5m2x8"
UPPER(LEFT(name, 1))
```

For example:

```text id="9c4v7k"
'a' → 'A'
'b' → 'B'
```

So:

```text id="1x8q3m"
aLice
 ↑
 A
```

---

# Step 3: Get Everything After the First Character

We use:

```sql id="k7p4m1"
SUBSTRING(name, 2)
```

`SUBSTRING()` extracts part of a string starting from a specified position.

The position is **1-based** in MySQL.

Therefore:

```text id="f2x9v6"
SUBSTRING('aLice', 2)
```

returns:

```text id="j8m3q5"
Lice
```

Similarly:

```text id="7k1p4x"
SUBSTRING('bOB', 2)
```

returns:

```text id="v5q9m2"
OB
```

---

# Step 4: Convert the Remaining Characters to Lowercase

We use:

```sql id="n6x2k8"
LOWER(SUBSTRING(name, 2))
```

For example:

```text id="w4p7m1"
Lice → lice
OB   → ob
```

So:

```text id="a9q3v6"
aLice
 ↓
A + lice
```

becomes:

```text id="c2m8x5"
Alice
```

---

# Step 5: Combine the Two Parts

We use:

```sql id="p7k4n2"
CONCAT(
    UPPER(LEFT(name, 1)),
    LOWER(SUBSTRING(name, 2))
)
```

`CONCAT()` combines strings together.

For:

```text id="q8m3v1"
name = 'aLice'
```

the calculation is:

```text id="6x2p9k"
UPPER(LEFT(name, 1))
→ A

LOWER(SUBSTRING(name, 2))
→ lice
```

Then:

```text id="r4n7c2"
CONCAT('A', 'lice')
→ 'Alice'
```

---

# Step 6: Why Don't We Use `LOWER(name)` Directly?

We could first convert the entire name to lowercase:

```sql id="k5m8x1"
LOWER(name)
```

For:

```text id="9v3q7p"
aLice
```

we get:

```text id="1m6x4k"
alice
```

But we need the first letter uppercase:

```text id="z8q2n5"
Alice
```

Therefore, we need to treat the first character separately.

The logic is:

```text id="j4p9v6"
name
 ↓
separate first character
 ↓
uppercase first character
 +
lowercase everything else
 ↓
combine
```

---

# Solution 2: `CONCAT()` + `UPPER()` + `LOWER()`

Another way to write the same logic is:

```sql id="t8m3q1"
SELECT
    user_id,
    CONCAT(
        UPPER(SUBSTRING(name, 1, 1)),
        LOWER(SUBSTRING(name, 2))
    ) AS name
FROM Users
ORDER BY user_id;
```

This is essentially the same solution.

The only difference is that instead of:

```sql id="v7k2p4"
LEFT(name, 1)
```

we use:

```sql id="x1m8q5"
SUBSTRING(name, 1, 1)
```

to get the first character.

---

# `LEFT()` vs `SUBSTRING()`

Both can extract the first character.

### Using `LEFT()`

```sql id="f4q9m2"
LEFT(name, 1)
```

means:

> Take 1 character from the left.

### Using `SUBSTRING()`

```sql id="n7x3k8"
SUBSTRING(name, 1, 1)
```

means:

> Start at position 1 and take 1 character.

Both produce the same result.

For example:

```text id="p5m2v9"
name = 'aLice'

LEFT(name, 1)
→ a

SUBSTRING(name, 1, 1)
→ a
```

`LEFT()` is slightly shorter and more intuitive for this particular problem.

---

# Step 7: Order the Result

The problem asks for the result ordered by `user_id`.

So we use:

```sql id="q6v1m8"
ORDER BY user_id;
```

For example:

```text id="w2k9p4"
2 → Bob
1 → Alice
```

would become:

```text id="c8m5x1"
1 → Alice
2 → Bob
```

---

# Important Concept: String Functions

This problem is mainly testing basic SQL string manipulation.

The important functions are:

### `UPPER()`

Converts a string to uppercase.

```sql id="z4p8m2"
UPPER('alice')
```

returns:

```text id="k7x3q9"
ALICE
```

### `LOWER()`

Converts a string to lowercase.

```sql id="n5m1v6"
LOWER('BOB')
```

returns:

```text id="r8q2x4"
bob
```

### `LEFT()`

Gets characters from the beginning.

```sql id="j6p9k3"
LEFT('Alice', 1)
```

returns:

```text id="7m4x1q"
A
```

### `SUBSTRING()`

Gets a portion of a string.

```sql id="c5v8n2"
SUBSTRING('Alice', 2)
```

returns:

```text id="q1m7p4"
lice
```

### `CONCAT()`

Combines strings.

```sql id="x9k3m6"
CONCAT('A', 'lice')
```

returns:

```text id="v2q8p5"
Alice
```

---

# Important Concept: SQL Does Not Modify the Original Table

Notice that we use:

```sql id="h4m8x1"
SELECT
    user_id,
    ...
FROM Users
```

We are **not** using:

```sql id="k7p2q9"
UPDATE Users
```

The problem asks us to **return the corrected names**, not permanently modify the database.

Therefore, we calculate the corrected name directly in the `SELECT`.

This is a common LeetCode pattern.

---

# Key Takeaway

The main pattern to remember is:

```sql id="m8q4x2"
CONCAT(
    UPPER(LEFT(name, 1)),
    LOWER(SUBSTRING(name, 2))
)
```

Think of it as:

```text id="p6v1k9"
                 name
                  ↓
        ┌─────────┴─────────┐
        ↓                   ↓
 first character       remaining characters
        ↓                   ↓
     UPPER()              LOWER()
        └─────────┬─────────┘
                  ↓
               CONCAT()
                  ↓
            Corrected name
```

For example:

```text id="x3m7q5"
aLice
 ↓
A + lice
 ↓
Alice

bOB
 ↓
B + ob
 ↓
Bob
```

The key SQL functions to remember are:

```text id="q9k2v6"
UPPER()     → uppercase
LOWER()     → lowercase
LEFT()      → characters from the beginning
SUBSTRING() → part of a string
CONCAT()    → combine strings
```

This is a simple but useful pattern for **cleaning and standardizing text data in SQL**.
