# 1517. Find Users With Valid E-Mails

> **Difficulty:** Easy

## Problem

We need to find users whose email addresses satisfy **all** of the following rules:

1. The email prefix must:

   * Start with a **letter** (`a-z` or `A-Z`).
   * Contain only:

     * letters
     * digits
     * underscore `_`
     * period `.`
     * dash `-`
2. The domain must be exactly:

   ```text
   @leetcode.com
   ```

   in lowercase.

### Table: `Users`

| Column Name | Type    | Description  |
| ----------- | ------- | ------------ |
| `user_id`   | int     | Primary key  |
| `name`      | varchar | User's name  |
| `mail`      | varchar | User's email |

---

# Solution: Regular Expression

```sql id="v5k8nm"
SELECT
    user_id,
    name,
    mail
FROM Users
WHERE mail REGEXP '^[A-Za-z][A-Za-z0-9_.-]*@leetcode\\.com$';
```

### Explanation

This problem is mainly about understanding **regular expressions (`REGEXP`)**.

The regular expression:

```text id="h0k2wa"
^[A-Za-z][A-Za-z0-9_.-]*@leetcode\.com$
```

describes exactly what a valid email looks like according to the problem.

Let's break it down piece by piece.

---

# Step 1: `^` — Start of the string

```text id="4g0t6v"
^
```

means:

> Start matching from the beginning of the email.

This is important because the prefix **must start with a letter**.

For example:

```text id="2z4z2j"
.shapo@leetcode.com
```

should be invalid.

Without `^`, a pattern could potentially find a valid-looking section somewhere in the string.

---

# Step 2: `[A-Za-z]` — First character must be a letter

```text id="y2zj4q"
[A-Za-z]
```

means:

> The first character must be a letter from `A` to `Z` or `a` to `z`.

This handles the requirement:

> The prefix name must start with a letter.

### Valid

```text id="iy9h3x"
winston@leetcode.com
bella-@leetcode.com
sally.come@leetcode.com
```

### Invalid

```text id="d8s4pg"
.shapo@leetcode.com
-hello@leetcode.com
_hello@leetcode.com
123hello@leetcode.com
```

Even though some of those characters are allowed **inside** the prefix, they cannot be the first character.

---

# Step 3: `[A-Za-z0-9_.-]` — Allowed characters

```text id="7x8qjp"
[A-Za-z0-9_.-]
```

means each character can be:

* `A-Z`
* `a-z`
* `0-9`
* `_`
* `.`
* `-`

These are exactly the characters allowed in the prefix.

For example:

```text id="3jv1i9"
john123@leetcode.com
john_doe@leetcode.com
john.doe@leetcode.com
john-doe@leetcode.com
```

are all valid.

---

# Step 4: `*` — Zero or more additional characters

```text id="x6q3oa"
*
```

means:

> The preceding character class can occur zero or more times.

So:

```text id="y6e4ju"
[A-Za-z0-9_.-]*
```

means:

> After the first letter, there can be zero or more allowed characters.

This means even:

```text id="k4o1eb"
a@leetcode.com
```

is valid.

The prefix consists of just one letter: `a`.

---

# Why separate the first character from the rest?

Notice that we have:

```text id="3x0x3q"
[A-Za-z][A-Za-z0-9_.-]*
```

instead of:

```text id="qv4b0g"
[A-Za-z0-9_.-]+
```

This is intentional.

The problem has **two different rules**:

> The first character must be a letter.

> The remaining characters can be letters, digits, `_`, `.`, or `-`.

So we explicitly represent those two rules:

```text id="l3v2bx"
[A-Za-z]
```

→ first character must be a letter

```text id="3h7ypr"
[A-Za-z0-9_.-]*
```

→ remaining characters can be any allowed character

---

# Step 5: `@leetcode.com` — Required domain

```text id="8b2d4v"
@leetcode\\.com
```

means the email must end with:

```text id="py2p1r"
@leetcode.com
```

The domain must be **exactly** `leetcode.com` in lowercase.

Therefore:

### Valid

```text id="n2y4bc"
john@leetcode.com
john123@leetcode.com
john.doe@leetcode.com
```

### Invalid

```text id="xqzqj9"
john@gmail.com
john@LeetCode.com
john@leetcode.org
john@leetcode.co
```

---

# Why is the `.` escaped?

In regular expressions, a period:

```text id="x4njc7"
.
```

has a special meaning.

It usually means:

> Match any single character.

But we need to match an **actual period** in:

```text
leetcode.com
```

Therefore we escape it:

```text id="3i5qjl"
\.
```

So:

```text id="w9b8d2"
leetcode\.com
```

means:

> Match the literal text `leetcode.com`.

In the SQL string, we write:

```sql id="g6k8jd"
'...@leetcode\\.com...'
```

because the backslash itself needs to be represented correctly inside the SQL string.

---

# Step 6: `$` — End of the string

```text id="c7y1kt"
$
```

means:

> The match must end at the end of the email.

This is important because we don't want something like:

```text id="xk8g9n"
john@leetcode.com@gmail.com
```

to be accepted.

The `$` ensures that after:

```text id="4zq1mx"
@leetcode.com
```

there is nothing else.

So:

```text id="3g7q5j"
^ ... $
```

means:

> Match the **entire email**, from beginning to end.

---

# Full Regex Breakdown

The complete pattern is:

```text id="3kq0p1"
^[A-Za-z][A-Za-z0-9_.-]*@leetcode\.com$
```

| Part              | Meaning                                |
| ----------------- | -------------------------------------- |
| `^`               | Start of string                        |
| `[A-Za-z]`        | First character must be a letter       |
| `[A-Za-z0-9_.-]*` | Zero or more allowed prefix characters |
| `@`               | Literal `@`                            |
| `leetcode`        | Exact lowercase text                   |
| `\.`              | Literal period                         |
| `com`             | Exact lowercase text                   |
| `$`               | End of string                          |

---

# Testing the Example

Consider:

```text id="6s9d2p"
winston@leetcode.com
```

### First character

```text id="d7w2cs"
w
```

`w` is a letter → ✅

### Remaining prefix

```text id="8m5qj1"
inston
```

All are letters → ✅

### Domain

```text id="j7n3ak"
@leetcode.com
```

Exactly matches the required domain → ✅

Therefore it is valid.

---

## Example: `bella-@leetcode.com`

First character:

```text id="g8j1sc"
b
```

→ letter ✅

Remaining prefix:

```text id="4u0p5s"
ella-
```

All characters are allowed → ✅

Domain:

```text id="k3h8q2"
@leetcode.com
```

→ correct ✅

Therefore it is valid.

---

## Example: `quarz#2020@leetcode.com`

The prefix contains:

```text id="x1v4z7"
#
```

But `#` is **not** included in:

```text id="4d2q6m"
[A-Za-z0-9_.-]
```

Therefore it does not match → ❌

---

## Example: `.shapo@leetcode.com`

The first character is:

```text id="j8p2w4"
.
```

But the first-character pattern is:

```text id="n6f3qa"
[A-Za-z]
```

A period isn't a letter → ❌

Therefore the email is invalid.

---

# Why `LIKE` Is Not Enough

We could use:

```sql id="m3q6yf"
WHERE mail LIKE '%@leetcode.com'
```

but this is **not sufficient**.

It would accept invalid prefixes such as:

```text id="b4z7wx"
.shapo@leetcode.com
quarz#2020@leetcode.com
12345@leetcode.com
```

The problem doesn't just ask:

> Does the email end with `@leetcode.com`?

It also specifies exactly which characters are allowed in the prefix and what the first character must be.

That's why a regular expression is appropriate.

---

# Why Not Just Check the Domain?

We could write:

```sql id="4g8t2v"
WHERE mail LIKE '%@leetcode.com'
```

but this only checks the domain.

The following invalid emails would still pass:

```text id="7c2k4m"
.shapo@leetcode.com
quarz#2020@leetcode.com
123@leetcode.com
```

So we need to validate **both**:

```text id="x6k3r2"
Prefix
+
Domain
```

The regular expression handles both at once.

---

# Important SQL Concepts

## 1. `REGEXP`

`REGEXP` allows us to filter strings using a **regular expression pattern**.

General pattern:

```sql id="9j3q7c"
WHERE column REGEXP 'pattern'
```

For example:

```sql id="n5f2qa"
WHERE name REGEXP '^[A-Z]'
```

would find names beginning with an uppercase letter.

---

## 2. Character Classes `[...]`

A character class specifies which characters are allowed.

For example:

```text id="j7v4x2"
[A-Z]
```

→ any uppercase letter

```text id="m8q1dz"
[a-z]
```

→ any lowercase letter

```text id="r5p3kf"
[0-9]
```

→ any digit

```text id="w6c9hs"
[A-Za-z0-9]
```

→ any letter or digit

Our pattern:

```text id="b3n7qa"
[A-Za-z0-9_.-]
```

allows letters, digits, underscore, period, and dash.

---

## 3. `*`

```text id="s2k8mn"
*
```

means:

> Zero or more occurrences.

So:

```text id="j4p6cx"
[A-Za-z0-9_.-]*
```

allows the prefix to contain any number of valid characters after the first letter.

---

## 4. `^` and `$`

These are called **anchors**.

```text id="h5m1vq"
^
```

→ beginning of the string

```text id="p8r3zk"
$
```

→ end of the string

Using both:

```text id="n2w7cx"
^pattern$
```

means:

> The entire string must match the pattern.

This is extremely useful when validating things such as:

* email addresses
* phone numbers
* IDs
* codes
* usernames
* formatted strings

---

# Key Takeaway

This problem is primarily a **regular expression pattern-matching** problem.

The main query is:

```sql id="6x0m5r"
SELECT
    user_id,
    name,
    mail
FROM Users
WHERE mail REGEXP '^[A-Za-z][A-Za-z0-9_.-]*@leetcode\\.com$';
```

The pattern:

```text id="0k7q3v"
^[A-Za-z][A-Za-z0-9_.-]*@leetcode\.com$
```

can be remembered as:

```text id="4v9q1c"
^
↓
must start here

[A-Za-z]
↓
first character = letter

[A-Za-z0-9_.-]*
↓
remaining prefix = allowed characters

@leetcode\.com
↓
exact required domain

$
↓
must end here
```

### The most important regex patterns to remember

```text id="k3p7s1"
[A-Za-z]       → any letter
[0-9]          → any digit
[A-Za-z0-9]    → letter or digit
*              → zero or more
+              → one or more
^              → beginning
$              → end
\.             → literal period
```

The key lesson is:

> **When a SQL problem gives you detailed rules about what characters a string can contain, `REGEXP` is usually the tool to reach for.**
