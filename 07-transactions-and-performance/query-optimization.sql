-- 07-transactions-and-performance / query-optimization.sql
-- Database: Chinook | MySQL 8.0.42
--
-- This file demonstrates common query patterns that can affect performance.
-- Use EXPLAIN to inspect the optimizer's plan, and EXPLAIN ANALYZE when you
-- need to compare estimates with the query's actual execution behavior.

USE chinook;

-- Q1: Select only the columns needed by the application.
-- SELECT * may read unnecessary data and can prevent MySQL from using a
-- covering index, even when an appropriate index exists.
EXPLAIN
SELECT * FROM invoiceline WHERE InvoiceId = 10;

-- This version requests only the required columns. If an index contains all
-- three columns, MySQL may be able to answer the query from the index alone.
EXPLAIN
SELECT InvoiceId, UnitPrice, Quantity FROM invoiceline WHERE InvoiceId = 10;


-- Q2: Keep indexed columns bare in predicates.
-- Applying YEAR() to InvoiceDate requires MySQL to evaluate the function for
-- rows before it can compare the result, which can prevent normal index use.

-- Slower: a function applied to the indexed column can disable index usage.
EXPLAIN
SELECT * FROM invoice WHERE YEAR(InvoiceDate) = 2010;

-- Faster: the equivalent half-open range preserves the original column value
-- and includes every timestamp in 2010 without any end-of-day ambiguity.
EXPLAIN
SELECT * FROM invoice
WHERE InvoiceDate >= '2010-01-01' AND InvoiceDate < '2011-01-01';


-- Q3: Avoid leading wildcards when an index should be used.
-- With '%love%', MySQL does not know the starting characters and cannot seek
-- directly to a portion of a normal sorted index.

-- Slower: the leading % generally requires scanning candidate rows.
EXPLAIN
SELECT * FROM track WHERE Name LIKE '%love%';

-- Faster when applicable: a fixed prefix lets MySQL seek to matching values.
EXPLAIN
SELECT * FROM track WHERE Name LIKE 'Love%';


-- Q4: Compare OR with separate indexed branches.
-- An OR across different columns can make it harder for MySQL to use either
-- index efficiently, although the best choice depends on data and indexes.

-- Slower in some data distributions: two different predicates are combined.
EXPLAIN
SELECT * FROM customer
WHERE Country = 'India' OR City = 'Mumbai';

-- UNION lets MySQL optimize each branch independently. UNION removes duplicate
-- rows, so it may create a temporary result; use UNION ALL only when duplicate
-- rows are known to be impossible or are intentionally wanted.
-- In this schema, Country may be indexed while City is not, so the second
-- branch can still require a scan. Always verify the result with EXPLAIN.
EXPLAIN
SELECT * FROM customer WHERE Country = 'India'
UNION
SELECT * FROM customer WHERE City = 'Mumbai';


-- Q5: Replace repeated correlated work when a set-based query is equivalent.
-- The correlated subquery is evaluated for each customer, which can become
-- expensive as the outer result grows.

-- Slower: count invoices separately for every customer row.
EXPLAIN
SELECT c.CustomerId, c.FirstName,
       (SELECT COUNT(*) FROM invoice AS i WHERE i.CustomerId = c.CustomerId) AS invoice_count
FROM customer AS c;

-- Faster in many cases: join once, aggregate by customer, and preserve
-- customers with no invoices through the LEFT JOIN.
EXPLAIN
SELECT c.CustomerId, c.FirstName, COUNT(i.InvoiceId) AS invoice_count
FROM customer AS c
LEFT JOIN invoice AS i ON c.CustomerId = i.CustomerId
GROUP BY c.CustomerId, c.FirstName;


-- Q6: Let an index support ORDER BY ... LIMIT when possible.
-- An index on InvoiceDate can provide rows in the required order, allowing
-- MySQL to stop after finding the first 10 rows instead of sorting everything.
-- Check EXPLAIN for the access type and for an avoidable "Using filesort".
EXPLAIN
SELECT InvoiceId, InvoiceDate, Total
FROM invoice
ORDER BY InvoiceDate DESC
LIMIT 10;


-- Q7: Inspect actual execution statistics, not only optimizer estimates.
-- EXPLAIN ANALYZE executes the statement and reports actual row counts and
-- timing, which helps identify inaccurate estimates or an unexpectedly costly
-- join, grouping, or sort. Run it only when executing the query is acceptable.
EXPLAIN ANALYZE
SELECT c.CustomerId, SUM(i.Total) AS total_spent
FROM customer AS c
INNER JOIN invoice AS i ON c.CustomerId = i.CustomerId
GROUP BY c.CustomerId
ORDER BY total_spent DESC;


-- Q8: Match values to the column's data type.
-- Email is VARCHAR. Comparing it to an unquoted number may force implicit
-- conversion and can prevent the unique Email index from being used normally.

-- Slower: the numeric literal does not match the VARCHAR column type.
EXPLAIN
SELECT * FROM customer WHERE Email = 12345;

-- Faster: the string literal matches the column type and keeps the predicate
-- suitable for normal index lookup.
EXPLAIN
SELECT * FROM customer WHERE Email = '12345';

-- End of query-optimization.sql
