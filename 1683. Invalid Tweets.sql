# 1683. Invalid Tweets

> **Difficulty:** Easy

## Problem

Find the IDs of tweets whose content contains **more than 15 characters**.

Return the result table in **any order**.

### Table: Tweets

| Column | Type |
|--------|------|
| tweet_id | int |
| content | varchar |

## SQL

```sql
SELECT tweet_id
FROM Tweets
WHERE LENGTH(content) > 15;
```

## Explanation

The `LENGTH()` function returns the number of characters in the `content` column.

- If the length of a tweet is **greater than 15**, it is considered invalid.
- The `WHERE` clause filters only those invalid tweets.
- The `SELECT` statement returns the corresponding `tweet_id`s.

## Solution 2: Using `CHAR_LENGTH()`

```sql
SELECT tweet_id
FROM Tweets
WHERE CHAR_LENGTH(content) > 15;
```

### Explanation

The `CHAR_LENGTH()` function returns the number of **characters** in a string.

- If the number of characters in `content` is **greater than 15**, the tweet is considered invalid.
- The `WHERE` clause filters only those invalid tweets.
- The `SELECT` statement returns the corresponding `tweet_id`s.

`CHAR_LENGTH()` is often preferred over `LENGTH()` because it counts **characters** rather than **bytes**. This is especially important when the string contains multibyte characters (such as emojis or non-English characters), where `LENGTH()` may return a larger value than the actual number of characters.

For this LeetCode problem, both `LENGTH()` and `CHAR_LENGTH()` produce the same result because the `content` consists only of alphanumeric characters, spaces, and `!`, all of which are single-byte characters.
