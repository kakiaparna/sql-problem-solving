-- 07-transactions-and-performance / query-optimization.sql
-- Database: Chinook | MySQL 8.0.42

USE chinook;

-- Q1: Compare SELECT * against selecting only the columns you actually need — SELECT * reads more data than necessary, and blocks MySQL from using a covering index even if one exists.
EXPLAIN
SELECT * FROM invoiceline WHERE InvoiceId = 10;

EXPLAIN
SELECT InvoiceId, UnitPrice, Quantity FROM invoiceline WHERE InvoiceId = 10;


-- Q2: Wrapping an indexed column in a function prevents MySQL from using the index on it at all — rewrite to a plain range condition instead, so the index remains usable.

-- Slower: function on the column disables index usage.
EXPLAIN
SELECT * FROM invoice WHERE YEAR(InvoiceDate) = 2010;

-- Faster: a plain range condition lets MySQL use an index on InvoiceDate if one exists.
EXPLAIN
SELECT * FROM invoice
WHERE InvoiceDate >= '2010-01-01' AND InvoiceDate < '2011-01-01';


-- Q3: A leading wildcard in LIKE prevents index usage, because MySQL can't use a sorted index to jump to a match if it doesn't know what the string starts with.

-- Slower: leading % means no index can help here.
EXPLAIN
SELECT * FROM track WHERE Name LIKE '%love%';

-- Faster (when applicable): a trailing-only wildcard CAN use an index, since MySQL can jump straight to matching prefixes.
EXPLAIN
SELECT * FROM track WHERE Name LIKE 'Love%';


-- Q4: An OR across two different columns often prevents MySQL from using either column's index efficiently — rewriting as a UNION lets each half of the condition use its own index.
-- - Slower: OR across two different indexed columns.
EXPLAIN
SELECT * FROM customer
WHERE Country = 'India' OR City = 'Mumbai';
 
-- Faster: UNION lets each condition use its own index separately — though note this only helps the Country side here, since
-- there's no index on City in this repo (so that half still does a full scan). UNION also builds a temporary table to remove
-- duplicates, which is its own real cost — worth weighing against the OR version rather than assuming UNION always wins outright.
EXPLAIN
SELECT * FROM customer WHERE Country = 'India'
UNION
SELECT * FROM customer WHERE City = 'Mumbai';

-- Q5: A correlated subquery re-runs once per outer row — rewriting the same logic as a JOIN often lets MySQL execute it far more efficiently as a single pass.

-- Slower: correlated subquery runs once per customer row.
EXPLAIN
SELECT c.CustomerId, c.FirstName,
       (SELECT COUNT(*) FROM invoice AS i WHERE i.CustomerId = c.CustomerId) AS invoice_count
FROM customer AS c;

-- Faster: equivalent result using a JOIN + GROUP BY instead.
EXPLAIN
SELECT c.CustomerId, c.FirstName, COUNT(i.InvoiceId) AS invoice_count
FROM customer AS c
LEFT JOIN invoice AS i ON c.CustomerId = i.CustomerId
GROUP BY c.CustomerId, c.FirstName;


-- Q6: When using ORDER BY with LIMIT, an index on the sorted column lets MySQL stop early instead of sorting the entire table first — check the plan to see if "Using filesort" appears
EXPLAIN
SELECT InvoiceId, InvoiceDate, Total
FROM invoice
ORDER BY InvoiceDate DESC
LIMIT 10;


-- Q7: Use EXPLAIN ANALYZE (not just EXPLAIN) to see the actual execution statistics — real row counts and real timing, not just MySQL's estimate.
EXPLAIN ANALYZE
SELECT c.CustomerId, SUM(i.Total) AS total_spent
FROM customer AS c
INNER JOIN invoice AS i ON c.CustomerId = i.CustomerId
GROUP BY c.CustomerId
ORDER BY total_spent DESC;


-- Q8: Comparing a column against a mismatched data type forces MySQL to convert every row before comparing, which silently disables index usage — always match the actual column type.

-- - Slower: Email is VARCHAR, but compared against a bare number —forces a type conversion on every row, disabling the unique index on Email entirely.
EXPLAIN
SELECT * FROM customer WHERE Email = 12345;
 
-- Faster: comparing against a properly quoted string lets the
-- index on Email be used normally.
EXPLAIN
SELECT * FROM customer WHERE Email = '12345';

-- End of query-optimization.sql