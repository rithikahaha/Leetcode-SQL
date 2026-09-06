# 626. Exchange Seats

> **Difficulty:** Medium

## Problem

We are given a `Seat` table containing students and their seat IDs.

The seat IDs are continuous, starting from `1`.

We need to **swap the seat IDs of every two consecutive students**:

* Student at `id = 1` swaps with student at `id = 2`
* Student at `id = 3` swaps with student at `id = 4`
* Student at `id = 5` swaps with student at `id = 6`
* And so on...
* If the number of students is **odd**, the last student remains in the same seat.

The result must be ordered by `id` in ascending order.

### Table: `Seat`

| Column    | Type    | Description                                      |
| --------- | ------- | ------------------------------------------------ |
| `id`      | int     | Primary key; continuous sequence starting from 1 |
| `student` | varchar | Student's name                                   |

### Example

**Input:**

| id | student |
| -: | ------- |
|  1 | Abbot   |
|  2 | Doris   |
|  3 | Emerson |
|  4 | Green   |
|  5 | Jeames  |

**Output:**

| id | student |
| -: | ------- |
|  1 | Doris   |
|  2 | Abbot   |
|  3 | Green   |
|  4 | Emerson |
|  5 | Jeames  |

The idea is to **change the ID assigned to each student**, not actually update the table.

---

## Solution 1: `CASE` + Arithmetic

```sql
SELECT
    CASE
        WHEN id % 2 = 1 AND id < (SELECT MAX(id) FROM Seat)
            THEN id + 1
        WHEN id % 2 = 0
            THEN id - 1
        ELSE id
    END AS id,
    student
FROM Seat
ORDER BY id;
```

### Explanation

The key observation is that the IDs follow a predictable pattern.

For every pair:

```text
1 ↔ 2
3 ↔ 4
5 ↔ 6
7 ↔ 8
```

So we can determine the new ID using whether the current ID is **odd or even**.

### Step 1: Handle odd IDs

```sql
id % 2 = 1
```

`%` gives the remainder after division.

For example:

```text
1 % 2 = 1  → odd
2 % 2 = 0  → even
3 % 2 = 1  → odd
4 % 2 = 0  → even
```

For an odd ID, the student should move **one seat forward**:

```sql
id + 1
```

So:

```text
1 → 2
3 → 4
5 → 6
```

However, if the number of students is odd, the final student should **not** move.

Therefore, we also check:

```sql
id < (SELECT MAX(id) FROM Seat)
```

This prevents the last odd ID from being changed.

For example, if the maximum ID is `5`:

```text
5 < 5 → FALSE
```

so student `5` stays at `5`.

---

### Step 2: Handle even IDs

```sql
WHEN id % 2 = 0
    THEN id - 1
```

Every even ID moves **one seat backward**.

For example:

```text
2 → 1
4 → 3
6 → 5
```

This creates the required swaps:

```text
1 → 2
2 → 1

3 → 4
4 → 3
```

---

### Step 3: Keep the last odd student unchanged

```sql
ELSE id
```

This handles the case where the number of students is odd and the current student is the last student.

For example:

```text
1  → 2
2  → 1
3  → 4
4  → 3
5  → 5
```

The `5` remains unchanged.

---

### Step 4: Why do we use `CASE`?

`CASE` allows us to assign a different value depending on a condition.

The logic is essentially:

```text
IF odd and not last → id + 1
IF even             → id - 1
OTHERWISE           → id
```

So:

```sql
CASE
    WHEN condition1 THEN result1
    WHEN condition2 THEN result2
    ELSE result3
END
```

is useful whenever a column's output depends on multiple conditions.

---

### Step 5: Why `MAX(id)`?

```sql
SELECT MAX(id) FROM Seat
```

returns the ID of the last student.

Because the problem guarantees that IDs start at `1` and increase continuously, the maximum ID is also the **number of students**.

For example:

```text
1, 2, 3, 4, 5
```

means:

```sql
MAX(id) = 5
```

Therefore, if the maximum ID is odd, that student is the one who should remain unchanged.

---

### Step 6: Why `ORDER BY id`?

The newly calculated `id` is what we want to display in ascending order:

```sql
ORDER BY id;
```

So the swapped students appear in their new seat positions:

```text
1
2
3
4
5
```

---

## Solution 2: `IF()` + Arithmetic

Because the swapping rule is based on whether the ID is odd or even, we can also use MySQL's `IF()` function.

```sql
SELECT
    IF(
        id = (SELECT MAX(id) FROM Seat) AND id % 2 = 1,
        id,
        IF(id % 2 = 1, id + 1, id - 1)
    ) AS id,
    student
FROM Seat
ORDER BY id;
```

### Explanation

The outer `IF()` handles the special case of an odd number of students:

```sql
IF(
    id = (SELECT MAX(id) FROM Seat) AND id % 2 = 1,
    id,
    ...
)
```

This means:

> If this is the last ID **and** it is odd, leave it unchanged.

Otherwise, we perform the normal swap:

```sql
IF(id % 2 = 1, id + 1, id - 1)
```

This means:

```text
odd  → move forward  → id + 1
even → move backward → id - 1
```

For IDs `1–5`:

| Original ID | Odd/Even   | New ID |
| ----------: | ---------- | -----: |
|           1 | Odd        |      2 |
|           2 | Even       |      1 |
|           3 | Odd        |      4 |
|           4 | Even       |      3 |
|           5 | Odd + Last |      5 |

Result:

```text
1 → Doris
2 → Abbot
3 → Green
4 → Emerson
5 → Jeames
```

---

## Important Concept: We Are Not Actually Updating the Table

A common point of confusion is that the problem says to "swap the seat id."

We do **not** need an `UPDATE` statement.

Instead, we calculate what the student's **new ID should be** in the `SELECT` statement:

```sql
SELECT
    calculated_new_id AS id,
    student
FROM Seat;
```

The original table remains unchanged.

The query simply produces the required result.

This is a useful SQL technique:

> **When a problem asks you to transform values in the output, you often don't need to modify the underlying table. You can calculate the transformed value directly in `SELECT`.**

---

## Important Concept: Odd vs Even IDs

This problem is a good example of using the modulo operator:

```sql
id % 2
```

The results are:

```text
id % 2 = 1 → odd
id % 2 = 0 → even
```

This allows us to recognize pairs without explicitly joining the table to itself.

The swapping pattern is:

```text
Odd ID  → ID + 1
Even ID → ID - 1
```

with one exception:

```text
Last odd ID → unchanged
```

---

## Why Doesn't the Last Even ID Need Special Handling?

Suppose there are `6` students:

```text
1 2 3 4 5 6
```

The pairs are:

```text
1 ↔ 2
3 ↔ 4
5 ↔ 6
```

The last ID is `6`, which is even.

Our normal rule:

```sql
id - 1
```

correctly changes:

```text
6 → 5
```

So the special case is only necessary when the last ID is **odd**.

For example:

```text
1 2 3 4 5
```

There is no `6` for student `5` to swap with.

---

## Key Takeaway

The most important pattern to remember from this problem is:

```sql
CASE
    WHEN id % 2 = 1 AND id < MAX_ID
        THEN id + 1
    WHEN id % 2 = 0
        THEN id - 1
    ELSE id
END
```

The reasoning is:

```text
Odd ID  → next ID
Even ID → previous ID
Last odd ID → unchanged
```

This problem is mainly testing your ability to combine:

* `CASE`
* `IF()`
* Modulo `%`
* Scalar subqueries
* `MAX()`
* `ORDER BY`
* Conditional value transformation
