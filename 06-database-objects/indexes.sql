-- 06-database-objects / indexes.sql
-- Database: Chinook 

USE chinook;

-- Q1: See what indexes already exist on the customer table before making any changes.
SHOW INDEX FROM customer;


-- Q2: Check the query plan for filtering customers by country BEFORE adding an index, to see if MySQL does a full table scan.
EXPLAIN
SELECT * FROM customercustomer
WHERE Country = 'India';


-- Q3: Create an index on the Country column, since it's a common filter condition in customer reports.
CREATE INDEX idx_customer_country
ON customer (Country);


-- Q4: Re-run the same EXPLAIN as Q2, now that the index exists,to compare the query plan (look for "ref" or "range" instead of "ALL" in the type column, and a lower "rows" estimate).
EXPLAIN
SELECT * FROM customer
WHERE Country = 'India';


-- Q5: Create a composite index on invoice, since reports often filter by CustomerId AND sort by InvoiceDate together.
CREATE INDEX idx_invoice_customer_date
ON invoice (CustomerId, InvoiceDate);


-- Q6: Check the query plan for a query that benefits from the composite index in Q5.
EXPLAIN
SELECT * FROM invoice
WHERE CustomerId = 5
ORDER BY InvoiceDate;


-- Q7: Create a UNIQUE index on customer email, since no two customers should share the same email address.
CREATE UNIQUE INDEX idx_customer_email_unique
ON customer (Email);


-- Q8: Create a covering index for a specific report — total price per invoice line — so MySQL can answer it using only the index, without reading the full invoiceline table.
CREATE INDEX idx_invoiceline_covering
ON invoiceline (InvoiceId, UnitPrice, Quantity);

-- Check the query plan: "Extra" should show "Using index" when the covering index is actually being used.
EXPLAIN
SELECT InvoiceId, UnitPrice, Quantity
FROM invoiceline
WHERE InvoiceId = 10;


-- Q9: Remove an index that's no longer needed.
DROP INDEX idx_customer_country ON customer;

SHOW INDEX FROM customer;
SHOW INDEX FROM invoiceline;

-- End of indexes.sql