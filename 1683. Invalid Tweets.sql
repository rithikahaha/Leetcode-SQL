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
