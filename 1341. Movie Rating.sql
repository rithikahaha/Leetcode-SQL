# 1341. Movie Rating

> **Difficulty:** Medium

## Problem

We are given three tables:

* `Movies` — contains movie IDs and movie titles.
* `Users` — contains user IDs and user names.
* `MovieRating` — contains ratings given by users to movies.

We need to return **two results**:

1. The name of the user who has rated the **greatest number of movies**.

   * If multiple users have rated the same maximum number of movies, return the **lexicographically smaller** name.

2. The name of the movie with the **highest average rating in February 2020**.

   * If multiple movies have the same average rating, return the **lexicographically smaller** movie title.

The final output must contain the two answers in a single column called `results`.

### Table: `Movies`

| Column     | Type    | Description         |
| ---------- | ------- | ------------------- |
| `movie_id` | int     | Primary key         |
| `title`    | varchar | Movie title; unique |

### Table: `Users`

| Column    | Type    | Description       |
| --------- | ------- | ----------------- |
| `user_id` | int     | Primary key       |
| `name`    | varchar | User name; unique |

### Table: `MovieRating`

| Column       | Type | Description               |
| ------------ | ---- | ------------------------- |
| `movie_id`   | int  | ID of the rated movie     |
| `user_id`    | int  | ID of the user who rated  |
| `rating`     | int  | Rating given to the movie |
| `created_at` | date | Date of the review        |

The primary key is `(movie_id, user_id)`, meaning one user can rate a particular movie only once.

---

# Solution 1: `UNION ALL` + `ORDER BY` + `LIMIT`

```sql
SELECT u.name AS results
FROM Users u
JOIN MovieRating mr
    ON u.user_id = mr.user_id
GROUP BY u.user_id, u.name
ORDER BY COUNT(*) DESC, u.name
LIMIT 1

UNION ALL

SELECT m.title AS results
FROM Movies m
JOIN MovieRating mr
    ON m.movie_id = mr.movie_id
WHERE mr.created_at >= '2020-02-01'
  AND mr.created_at < '2020-03-01'
GROUP BY m.movie_id, m.title
ORDER BY AVG(mr.rating) DESC, m.title
LIMIT 1;
```

### Important Note

In MySQL, when using `ORDER BY` and `LIMIT` independently for two queries combined with `UNION ALL`, it is safer to wrap each query in a subquery:

```sql
SELECT results
FROM (
    SELECT u.name AS results
    FROM Users u
    JOIN MovieRating mr
        ON u.user_id = mr.user_id
    GROUP BY u.user_id, u.name
    ORDER BY COUNT(*) DESC, u.name
    LIMIT 1
) a

UNION ALL

SELECT results
FROM (
    SELECT m.title AS results
    FROM Movies m
    JOIN MovieRating mr
        ON m.movie_id = mr.movie_id
    WHERE mr.created_at >= '2020-02-01'
      AND mr.created_at < '2020-03-01'
    GROUP BY m.movie_id, m.title
    ORDER BY AVG(mr.rating) DESC, m.title
    LIMIT 1
) b;
```

This is the version to use for the LeetCode submission.

---

## Part 1: Find the User With the Most Ratings

```sql
SELECT u.name AS results
FROM Users u
JOIN MovieRating mr
    ON u.user_id = mr.user_id
GROUP BY u.user_id, u.name
ORDER BY COUNT(*) DESC, u.name
LIMIT 1;
```

Let's break this down.

### Step 1: Join `Users` and `MovieRating`

```sql
JOIN MovieRating mr
    ON u.user_id = mr.user_id
```

`MovieRating` contains `user_id`, but we need the **user's name**.

For example:

```text
MovieRating
user_id = 1
```

needs to be connected to:

```text
Users
user_id = 1
name = Daniel
```

So we join the tables using:

```sql
u.user_id = mr.user_id
```

The result conceptually looks like:

| name   | movie_id | rating |
| ------ | -------: | -----: |
| Daniel |        1 |      3 |
| Daniel |        2 |      5 |
| Daniel |        3 |      3 |
| Monica |        1 |      4 |
| Monica |        2 |      2 |
| Monica |        3 |      4 |

Now every rating is associated with the user's name.

---

### Step 2: Group by User

```sql
GROUP BY u.user_id, u.name
```

We want to count how many movies **each user** has rated.

Therefore, we create one group for each user.

For example:

```text
Daniel → 3 ratings
Monica → 3 ratings
Maria  → 2 ratings
James  → 1 rating
```

We group by both:

```sql
u.user_id, u.name
```

Even though `name` is unique, including both columns makes the grouping explicit.

---

### Step 3: Count Ratings

```sql
COUNT(*)
```

Each row in `MovieRating` represents one rating.

Therefore:

```sql
COUNT(*)
```

counts how many ratings each user has given.

Because `(movie_id, user_id)` is the primary key, a user cannot have duplicate ratings for the same movie.

So counting the rating rows gives us the number of movies rated by each user.

---

### Step 4: Sort by Number of Ratings

```sql
ORDER BY COUNT(*) DESC
```

We want the user with the **greatest number** of ratings.

Therefore, we sort the count from largest to smallest:

```text
3
3
2
1
```

`DESC` means descending order.

---

### Step 5: Handle the Tie

The problem says:

> If there is a tie, return the lexicographically smaller user name.

So we add:

```sql
ORDER BY COUNT(*) DESC, u.name
```

The sorting happens in this order:

1. Highest rating count first.
2. If counts are equal, smallest name alphabetically/lexicographically first.

For example:

```text
Daniel → 3
Monica → 3
```

Both have `3`.

SQL then compares:

```text
Daniel
Monica
```

Since `Daniel` comes first lexicographically, Daniel is selected.

### What Does Lexicographical Order Mean?

It is essentially dictionary-style ordering for strings.

For example:

```text
Daniel
James
Maria
Monica
```

And:

```text
"Daniel" < "Monica"
```

So:

```sql
ORDER BY u.name
```

gives us the smaller name first.

---

### Step 6: Return Only One User

```sql
LIMIT 1
```

After sorting, the first row is the correct answer.

So:

```sql
LIMIT 1
```

returns only that user.

---

# Part 2: Find the Movie With the Highest Average Rating in February 2020

```sql
SELECT m.title AS results
FROM Movies m
JOIN MovieRating mr
    ON m.movie_id = mr.movie_id
WHERE mr.created_at >= '2020-02-01'
  AND mr.created_at < '2020-03-01'
GROUP BY m.movie_id, m.title
ORDER BY AVG(mr.rating) DESC, m.title
LIMIT 1;
```

This is a separate problem from the first part.

Now we care about:

* Movies
* Ratings
* February 2020
* Average rating
* Lexicographical tie-breaking

---

## Step 1: Join `Movies` and `MovieRating`

```sql
JOIN MovieRating mr
    ON m.movie_id = mr.movie_id
```

`MovieRating` gives us the movie ID and rating, while `Movies` gives us the movie title.

For example:

```text
MovieRating
movie_id = 2
rating = 5
```

joins with:

```text
Movies
movie_id = 2
title = Frozen 2
```

So we can calculate the average rating for each movie by title.

---

## Step 2: Filter to February 2020

```sql
WHERE mr.created_at >= '2020-02-01'
  AND mr.created_at < '2020-03-01'
```

We only want ratings created during February 2020.

The condition means:

```text
2020-02-01 ≤ created_at < 2020-03-01
```

So dates included are:

```text
2020-02-01
2020-02-02
...
2020-02-28
2020-02-29
```

and dates in January or March are excluded.

### Why use `< '2020-03-01'`?

We could write:

```sql
WHERE created_at BETWEEN '2020-02-01' AND '2020-02-29'
```

but using:

```sql
created_at >= '2020-02-01'
AND created_at < '2020-03-01'
```

is a very useful date-filtering pattern.

It means:

> Include everything from the beginning of February up to, but not including, March.

This is especially useful when a column contains timestamps as well as dates.

---

## Step 3: Group by Movie

```sql
GROUP BY m.movie_id, m.title
```

We need one average rating for each movie.

For example, after filtering to February:

```text
Frozen 2:
5
2

Joker:
3
4

Avengers:
4
2
```

Grouping by movie allows us to calculate:

```text
Frozen 2 → AVG(5,2) = 3.5
Joker    → AVG(3,4) = 3.5
Avengers → AVG(4,2) = 3.0
```

---

## Step 4: Calculate the Average

```sql
AVG(mr.rating)
```

`AVG()` calculates the arithmetic mean:

```text
sum of ratings
----------------
number of ratings
```

For Frozen 2:

```text
(5 + 2) / 2
= 3.5
```

For Joker:

```text
(3 + 4) / 2
= 3.5
```

---

## Step 5: Sort by Highest Average

```sql
ORDER BY AVG(mr.rating) DESC
```

We want the movie with the highest average rating.

So we sort from largest to smallest:

```text
3.5
3.5
3.0
```

---

## Step 6: Handle Equal Averages

The problem says that if multiple movies have the same average rating, return the lexicographically smaller movie name.

So we write:

```sql
ORDER BY AVG(mr.rating) DESC, m.title
```

The first sorting criterion is:

```sql
AVG(mr.rating) DESC
```

and the second is:

```sql
m.title
```

Therefore:

```text
Frozen 2 → 3.5
Joker    → 3.5
```

Since both have the same average, SQL compares their titles:

```text
Frozen 2
Joker
```

`Frozen 2` comes first lexicographically.

---

## Step 7: Return Only the Best Movie

```sql
LIMIT 1
```

After sorting, the first row is the movie we need.

Therefore:

```sql
LIMIT 1
```

returns only the best movie.

---

# Part 3: Combine the Two Answers

We now have two separate queries:

### Query 1 — Best User

```sql
SELECT u.name AS results
FROM Users u
JOIN MovieRating mr
    ON u.user_id = mr.user_id
GROUP BY u.user_id, u.name
ORDER BY COUNT(*) DESC, u.name
LIMIT 1;
```

### Query 2 — Best Movie

```sql
SELECT m.title AS results
FROM Movies m
JOIN MovieRating mr
    ON m.movie_id = mr.movie_id
WHERE mr.created_at >= '2020-02-01'
  AND mr.created_at < '2020-03-01'
GROUP BY m.movie_id, m.title
ORDER BY AVG(mr.rating) DESC, m.title
LIMIT 1;
```

We need to combine them vertically.

For that, we use:

```sql
UNION ALL
```

---

## Why `UNION ALL`?

`UNION ALL` combines the results of two queries by putting the rows one after another.

For example:

```text
Query 1:
Daniel

Query 2:
Frozen 2
```

becomes:

```text
Daniel
Frozen 2
```

We use `UNION ALL` rather than `UNION` because these are two separate required results.

`UNION` would remove duplicate rows if both answers happened to have the same text, while `UNION ALL` preserves both results.

---

# Final Solution

```sql
SELECT results
FROM (
    SELECT u.name AS results
    FROM Users u
    JOIN MovieRating mr
        ON u.user_id = mr.user_id
    GROUP BY u.user_id, u.name
    ORDER BY COUNT(*) DESC, u.name
    LIMIT 1
) a

UNION ALL

SELECT results
FROM (
    SELECT m.title AS results
    FROM Movies m
    JOIN MovieRating mr
        ON m.movie_id = mr.movie_id
    WHERE mr.created_at >= '2020-02-01'
      AND mr.created_at < '2020-03-01'
    GROUP BY m.movie_id, m.title
    ORDER BY AVG(mr.rating) DESC, m.title
    LIMIT 1
) b;
```

### Result

```text
+---------+
| results |
+---------+
| Daniel  |
| Frozen 2|
+---------+
```

---

# Important Concepts to Remember

## 1. `ORDER BY` Can Handle Tie-Breaking

A very useful pattern from this problem is:

```sql
ORDER BY primary_condition DESC, tie_breaker ASC
```

For the first requirement:

```sql
ORDER BY COUNT(*) DESC, u.name
```

means:

> Give me the user with the most ratings, and if there is a tie, choose the smaller name.

For the second:

```sql
ORDER BY AVG(mr.rating) DESC, m.title
```

means:

> Give me the movie with the highest average rating, and if there is a tie, choose the smaller title.

This is an extremely common SQL interview pattern.

---

## 2. `LIMIT 1` After Sorting

When a question says:

> Find the highest / lowest / most / least...

a common pattern is:

```sql
ORDER BY something DESC
LIMIT 1
```

For the smallest:

```sql
ORDER BY something ASC
LIMIT 1
```

When there is a tie-breaker:

```sql
ORDER BY something DESC, name ASC
LIMIT 1
```

---

## 3. `COUNT()` vs `AVG()`

The two halves of this problem use different aggregate functions.

### User requirement

We need to know:

> How many movies did each user rate?

So:

```sql
COUNT(*)
```

### Movie requirement

We need to know:

> What is the average rating for each movie?

So:

```sql
AVG(rating)
```

Always identify **what the question is measuring** before choosing the aggregate function.

---

## 4. `WHERE` Before `GROUP BY`

Notice the second query:

```sql
WHERE mr.created_at >= '2020-02-01'
  AND mr.created_at < '2020-03-01'
GROUP BY m.movie_id, m.title
```

The filtering happens **before** the grouping.

This is important.

We first remove ratings outside February:

```text
January ratings → removed
February ratings → kept
March ratings → removed
```

Then we calculate:

```sql
AVG(rating)
```

on the remaining February ratings.

If we calculated the average first and filtered afterward, we could end up using ratings from the wrong months.

---

## 5. `GROUP BY` + Aggregate

The general pattern is:

```sql
SELECT category,
       AGGREGATE(value)
FROM table
GROUP BY category;
```

Here:

### For users:

```sql
SELECT u.name,
       COUNT(*)
FROM Users u
JOIN MovieRating mr
    ON u.user_id = mr.user_id
GROUP BY u.name;
```

### For movies:

```sql
SELECT m.title,
       AVG(mr.rating)
FROM Movies m
JOIN MovieRating mr
    ON m.movie_id = mr.movie_id
GROUP BY m.title;
```

The `GROUP BY` tells SQL:

> Calculate the aggregate separately for each user/movie.

---

## Key Takeaway

This problem combines several **very common SQL interview patterns**:

```text
JOIN
  ↓
WHERE
  ↓
GROUP BY
  ↓
COUNT / AVG
  ↓
ORDER BY aggregate DESC, name ASC
  ↓
LIMIT 1
```

The two requirements can be thought of as:

```text
1. User with most ratings
   → COUNT(*) + ORDER BY DESC + name tie-breaker

2. Movie with highest February average
   → WHERE February
   → AVG(rating)
   → ORDER BY DESC + title tie-breaker

3. Combine both answers
   → UNION ALL
```

The most important pattern to remember is:

```sql
ORDER BY aggregate DESC, name
LIMIT 1
```

Whenever a LeetCode question says **"highest/most, and if tied choose lexicographically smallest"**, this pattern should immediately come to mind.
