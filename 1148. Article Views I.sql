# 1148. Article Views I

> **Difficulty:** Easy

## Problem

Find all authors who have viewed **at least one of their own articles**.

Return the result table sorted by `id` in **ascending order**.

### Table: Views

| Column | Type |
|--------|------|
| article_id | int |
| author_id | int |
| viewer_id | int |
| view_date | date |

## SQL

```sql
SELECT DISTINCT author_id AS id
FROM Views
WHERE author_id = viewer_id
ORDER BY id;
```

## Explanation

The query returns authors who have viewed their own articles.

- `author_id = viewer_id` filters rows where the author and viewer are the same person.
- `DISTINCT` removes duplicate author IDs since the table may contain duplicate rows or an author may view their own article multiple times.
- `AS id` renames the output column to `id` as required.
- `ORDER BY id` sorts the result in ascending order.
