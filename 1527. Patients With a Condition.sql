# 1527. Patients With a Condition

> **Difficulty:** Easy

## Problem

We are given a `Patients` table containing patient information and their medical conditions.

The `conditions` column contains **zero or more condition codes separated by spaces**.

We need to find patients who have **Type I Diabetes**.

The important rule is:

> Type I Diabetes condition codes always start with the prefix `DIAB1`.

However, we need to make sure that `DIAB1` appears as a **complete condition code**, not merely as part of another code.

For example:

```text
DIAB100 → valid
ACNE DIAB100 → valid
DIAB201 → valid
```

But a condition such as:

```text
XDIAB100
```

should not match because `DIAB1` is not the beginning of a separate condition code.

### Table: `Patients`

| Column         | Type    | Description                     |
| -------------- | ------- | ------------------------------- |
| `patient_id`   | int     | Patient ID; primary key         |
| `patient_name` | varchar | Patient's name                  |
| `conditions`   | varchar | Space-separated condition codes |

---

# Solution 1: `LIKE` with Space Boundaries

```sql id="8q4m1v"
SELECT
    patient_id,
    patient_name,
    conditions
FROM Patients
WHERE conditions LIKE 'DIAB1%'
   OR conditions LIKE '% DIAB1%';
```

### Explanation

The trick is to recognize that `conditions` is not a single condition.

It can contain multiple condition codes separated by spaces.

For example:

```text
YFEV COUGH
```

contains:

```text
YFEV
COUGH
```

while:

```text
ACNE DIAB100
```

contains:

```text
ACNE
DIAB100
```

We need to find a condition code that **starts with `DIAB1`**.

---

# Step 1: Understand `LIKE`

The SQL `LIKE` operator is used for pattern matching.

The `%` wildcard means:

> Match zero or more characters.

For example:

```sql id="5m8x2q"
conditions LIKE 'DIAB1%'
```

matches values beginning with `DIAB1`.

Examples:

```text
DIAB100 → match
DIAB101 → match
DIAB123 → match
```

because all of them start with:

```text
DIAB1
```

---

# Step 2: Why Isn't `LIKE 'DIAB1%'` Enough?

Consider:

```text
ACNE DIAB100
```

The condition `DIAB100` starts with `DIAB1`, but the entire `conditions` string starts with `ACNE`.

Therefore:

```sql id="w3q7n1"
conditions LIKE 'DIAB1%'
```

would **not** match:

```text
ACNE DIAB100
```

But this patient should be included.

So we need a second pattern for cases where `DIAB1...` appears **after another condition**.

---

# Step 3: Match `DIAB1` After a Space

We use:

```sql id="p9k4m2"
conditions LIKE '% DIAB1%'
```

The important part is:

```text id="x7m3q8"
 DIAB1
```

There is a **space before `DIAB1`**.

This ensures that `DIAB1` starts a new condition code.

For:

```text
ACNE DIAB100
```

the pattern finds:

```text
ACNE [DIAB100]
     ↑
```

and therefore matches.

---

# Step 4: Why Do We Need Two Conditions?

The Type I Diabetes code can occur in two relevant positions.

### Case 1: It is the first condition

```text
DIAB100 MYOP
```

We use:

```sql id="m6q2v9"
conditions LIKE 'DIAB1%'
```

### Case 2: It occurs after another condition

```text
ACNE DIAB100
```

We use:

```sql id="r4x8k1"
conditions LIKE '% DIAB1%'
```

So we combine them with:

```sql id="v2n7q5"
OR
```

The complete condition becomes:

```sql id="j8m3c6"
WHERE conditions LIKE 'DIAB1%'
   OR conditions LIKE '% DIAB1%';
```

This means:

> Match if a condition beginning with `DIAB1` occurs either at the beginning of the string or after a space.

---

# Step 5: Why Does This Not Match `DIAB201`?

The prefix required is:

```text id="q5x9m2"
DIAB1
```

But:

```text id="7n3v8k"
DIAB201
```

starts with:

```text id="m4q6p1"
DIAB2
```

not:

```text id="z8x2c5"
DIAB1
```

Therefore it does not match.

---

# Step 6: Why Does This Not Match a Code Like `XDIAB100`?

Consider:

```text
XDIAB100
```

The substring `DIAB1` exists inside it, but it is not the **start of the condition code**.

Our patterns require either:

```text id="c7m1x4"
DIAB1...
```

at the beginning of the string, or:

```text id="n9q5v2"
 DIAB1...
```

after a space.

Since `XDIAB100` has:

```text id="a6k8p3"
XDIAB100
```

there is no space immediately before `DIAB1`.

Therefore it is not matched.

This is why the space in:

```sql id="f4m7q1"
'% DIAB1%'
```

is important.

---

# Step 7: Why Isn't `%DIAB1%` Correct?

It might be tempting to write:

```sql id="t8x3m6"
WHERE conditions LIKE '%DIAB1%'
```

But this is too broad.

It means:

> Find `DIAB1` anywhere in the entire string.

That could incorrectly match something like:

```text
XDIAB100
```

because `DIAB1` appears inside the code.

The problem says the condition **starts with** `DIAB1`, so we need to identify the beginning of an individual condition code.

---

# Solution 2: Add a Space Around the Entire String

A cleaner way to think about the boundary is to add spaces around `conditions`.

```sql id="k5q8m3"
SELECT
    patient_id,
    patient_name,
    conditions
FROM Patients
WHERE CONCAT(' ', conditions, ' ') LIKE '% DIAB1%';
```

### Explanation

This solution turns:

```text
DIAB100 MYOP
```

conceptually into:

```text
 DIAB100 MYOP 
```

and:

```text
ACNE DIAB100
```

into:

```text
 ACNE DIAB100 
```

Now every condition has a space before and after it.

So we can simply search for:

```sql id="v1m7x4"
'% DIAB1%'
```

The pattern means:

> Find a space followed by `DIAB1`.

Therefore it can only match `DIAB1` at the beginning of a condition code.

---

## Why Does This Also Handle the First Condition?

Suppose:

```text
conditions = 'DIAB100 MYOP'
```

After adding spaces:

```text
' DIAB100 MYOP '
```

The beginning becomes:

```text
 DIAB100
```

which matches:

```sql id="q9k2c6"
'% DIAB1%'
```

So we don't need a separate condition for the beginning of the string.

---

# Comparing the Two Solutions

### Solution 1

```sql id="z6p3m8"
WHERE conditions LIKE 'DIAB1%'
   OR conditions LIKE '% DIAB1%';
```

This explicitly handles:

```text
DIAB1... at the beginning
```

and:

```text
DIAB1... after a space
```

### Solution 2

```sql id="w4n8q1"
WHERE CONCAT(' ', conditions, ' ') LIKE '% DIAB1%';
```

This creates a boundary around the entire string and lets one pattern handle both cases.

Both approaches work.

For learning purposes, **Solution 1 makes the two possible positions especially clear**.

---

# Important Concept: `%` Wildcard

The `%` wildcard is one of the most important parts of `LIKE`.

### `%` after a pattern

```sql id="p7m2x9"
LIKE 'DIAB1%'
```

means:

> Starts with `DIAB1`.

Examples:

```text
DIAB100
DIAB123
DIAB1XYZ
```

all match.

### `%` before a pattern

```sql id="c4q8v1"
LIKE '% DIAB1%'
```

means:

> Somewhere in the string, find a space followed by `DIAB1`, with anything allowed before and after it.

---

# Important Concept: Spaces as Delimiters

The `conditions` column stores multiple values in a single string:

```text
ACNE DIAB100 COUGH
```

The space acts as a **delimiter** separating the condition codes.

So:

```text
ACNE | DIAB100 | COUGH
```

can be thought of as three separate values.

Since the problem guarantees that condition codes are separated by spaces, we can use the space to identify the beginning of a condition.

This is why:

```sql id="n5x7q2"
'% DIAB1%'
```

is safer than:

```sql id="v8m3k6"
'%DIAB1%'
```

---

# Important Concept: `OR` vs `AND`

We use:

```sql id="r2q9m5"
condition1
OR
condition2
```

because **either position** is acceptable.

The condition can be:

```text
at the beginning
```

OR:

```text
after another condition
```

If we used `AND`:

```sql id="j6v1x8"
WHERE conditions LIKE 'DIAB1%'
  AND conditions LIKE '% DIAB1%'
```

the same string would need to satisfy both patterns simultaneously.

That would incorrectly exclude:

```text
DIAB100 MYOP
```

because it doesn't have a space before the first condition.

---

# Key Takeaway

The main pattern to remember is:

```sql id="m7q4x2"
WHERE conditions LIKE 'DIAB1%'
   OR conditions LIKE '% DIAB1%';
```

The logic is:

```text
DIAB1... at beginning
        OR
 DIAB1... after a space
```

The key idea is:

> **When multiple codes are stored in a space-separated string, use the space as a boundary so that you match a complete code prefix rather than a substring inside another code.**

Useful `LIKE` patterns to remember:

```text
'ABC%'       → starts with ABC
'%ABC'       → ends with ABC
'%ABC%'      → contains ABC anywhere
'% ABC%'     → contains ABC after a space
```

For this problem, the important distinction is:

```sql id="x9m3q7"
'%DIAB1%'
```

can match `DIAB1` **anywhere inside a code**,

while:

```sql id="k2v8p4"
'% DIAB1%'
```

requires `DIAB1` to begin immediately after a **space**, making it the start of a separate condition code.
