# 620. Not Boring Movies

> **Difficulty:** Easy

## Problem

Report all movies that:

- Have an **odd-numbered ID**, and
- Have a description that is **not** `"boring"`.

Return the result table ordered by **`rating`** in **descending order**.

### Table: Cinema

| Column | Type |
|--------|------|
| id | int |
| movie | varchar |
| description | varchar |
| rating | float |

---

## Solution 1: Using Modulo Operator (`%`)

```sql
SELECT *
FROM Cinema
WHERE id % 2 = 1
  AND description <> 'boring'
ORDER BY rating DESC;
```

### Explanation

This solution filters the required movies using the modulo (`%`) operator.

#### Step 1: Find odd-numbered IDs

```sql
id % 2 = 1
```

The modulo operator (`%`) returns the remainder after division.

Examples:

| id | id % 2 |
|---:|-------:|
| 1 | 1 |
| 2 | 0 |
| 3 | 1 |
| 4 | 0 |
| 5 | 1 |

Only odd numbers have a remainder of `1`.

#### Step 2: Exclude boring movies

```sql
description <> 'boring'
```

The `<>` operator means **not equal to**.

Only movies whose description is **not** `"boring"` are included.

#### Step 3: Sort the result

```sql
ORDER BY rating DESC
```

This sorts the remaining movies by rating from **highest** to **lowest**.

> **Note:** In SQL, `<>` is the standard operator for **not equal to**. Most database systems also support `!=`, but `<>` is ANSI SQL compliant and more portable.

---

## Solution 2: Using `MOD()`

```sql
SELECT *
FROM Cinema
WHERE MOD(id, 2) = 1
  AND description <> 'boring'
ORDER BY rating DESC;
```

### Explanation

This solution uses the `MOD()` function instead of the modulo (`%`) operator.

```sql
MOD(id, 2)
```

returns the remainder after dividing `id` by `2`.

Examples:

| id | MOD(id,2) |
|---:|----------:|
| 1 | 1 |
| 2 | 0 |
| 3 | 1 |
| 4 | 0 |
| 5 | 1 |

Since odd numbers leave a remainder of `1`, the condition:

```sql
MOD(id, 2) = 1
```

selects only movies with odd-numbered IDs.

The remaining conditions work exactly as in Solution 1.

> **Note:** `MOD()` and the `%` operator produce the same result in MySQL. Some database systems support only `MOD()`, making it a more portable choice.

---

## Solution 3: Using `!=`

```sql
SELECT *
FROM Cinema
WHERE id % 2 = 1
  AND description != 'boring'
ORDER BY rating DESC;
```

### Explanation

This solution is identical to Solution 1 except that it uses:

```sql
!=
```

instead of

```sql
<>
```

Both operators mean **not equal to** in MySQL.

The query:

- Selects movies with odd IDs.
- Excludes movies whose description is `"boring"`.
- Sorts the remaining movies by rating in descending order.

> **Note:** While `!=` is supported by MySQL and many other databases, `<>` is the ANSI SQL standard and is generally preferred when writing portable SQL.
