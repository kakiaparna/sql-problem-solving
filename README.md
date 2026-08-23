# SQL Problem Solving

90+ SQL problems solved from scratch — covering schema design, joins, window functions, stored procedures, and query optimization — against the Sakila and Chinook databases, while preparing for Data Analyst interviews.

## Environment

MySQL 8.0.42

## Datasets

- **[Sakila](https://dev.mysql.com/doc/index-other.html)** — MySQL's official sample database (DVD rental store: film, customer, rental, payment, staff, store)
- **[Chinook](https://github.com/lerocha/chinook-database)** — digital music store (artists, albums, tracks, invoices, customers, employees)

## Structure

| # | Category | Covers |
|---|---|---|
| 01 | Schema Design | DDL — CREATE, ALTER, DROP, TRUNCATE, constraints, keys |
| 02 | Data Manipulation | DML — INSERT, UPDATE, DELETE, UPSERT |
| 03 | Querying Fundamentals | SELECT/WHERE/ORDER BY, joins, aggregations (GROUP BY/HAVING), NULL handling |
| 04 | Intermediate Querying | Subqueries, string/date functions, CASE/pivoting, set operations |
| 05 | Advanced Querying | CTEs, recursive CTEs, window functions |
| 06 | Database Objects | Views, indexes, stored procedures, functions, triggers, temp tables |
| 07 | Transactions & Performance | Transactions, query optimization, permissions (GRANT/REVOKE) |
| 08 | Case Studies | Multi-concept, interview-style mixed problems |

## Format

Each `.sql` file contains multiple problems on that topic. Every problem includes the question as a comment, followed by the query and a short note on approach.

```sql
-- Q: Find the top 5 customers by total payment amount.
SELECT customer_id, SUM(amount) AS total_paid
FROM payment
GROUP BY customer_id
ORDER BY total_paid DESC
LIMIT 5;

```
