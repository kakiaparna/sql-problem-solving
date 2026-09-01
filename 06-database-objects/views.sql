-- 06-database-objects / views.sql
-- Database: Chinook 

USE chinook;

-- Q1: Create a simple view exposing only customer contact details, hiding internal columns like SupportRepId.
CREATE VIEW customer_contacts AS
SELECT CustomerId, FirstName, LastName, Email, Country
FROM customer;

-- Query it like a normal table:
SELECT * FROM customer_contacts
WHERE Country = 'India';


-- Q2: Create a view that joins invoice with customer, so invoice details always show the customer's name without repeating the join logic in every query.
CREATE VIEW invoice_details AS
SELECT i.InvoiceId, i.InvoiceDate, i.Total,
       c.CustomerId, c.FirstName, c.LastName, c.Country
FROM invoice AS i
INNER JOIN customer AS c ON i.CustomerId = c.CustomerId;

-- Query it like a normal table:
SELECT * FROM invoice_details
WHERE Total > 10
ORDER BY Total DESC;


-- Q3: Create a view that pre-aggregates total revenue per customer, so reporting queries don't need to repeat GROUP BY logic.
CREATE VIEW customer_revenue AS
SELECT CustomerId, SUM(Total) AS total_spent, COUNT(*) AS total_invoices
FROM invoice
GROUP BY CustomerId;

-- Query it like a normal table:
SELECT * FROM customer_revenue
WHERE total_spent > 40
ORDER BY total_spent DESC;


-- Q4: Create a reporting view for revenue per genre, combining three tables so analysts can query genre performance directly.
CREATE VIEW genre_revenue AS
SELECT g.Name AS genre_name,
       SUM(il.UnitPrice * il.Quantity) AS revenue
FROM invoiceline AS il
INNER JOIN track AS t ON il.TrackId = t.TrackId
INNER JOIN genre AS g ON t.GenreId = g.GenreId
GROUP BY g.Name;

-- Query it like a normal table:
SELECT * FROM genre_revenue
ORDER BY revenue DESC;


-- Q5: Update the customer_contacts view to also include Phone (CREATE OR REPLACE, since the view already exists).
CREATE OR REPLACE VIEW customer_contacts AS
SELECT CustomerId, FirstName, LastName, Email, Phone, Country
FROM customer;


-- Q6: Build a view on top of another view — a "high value customers" view built directly from customer_revenue.
CREATE VIEW high_value_customers AS
SELECT CustomerId, total_spent
FROM customer_revenue
WHERE total_spent > 45;

-- Query it like a normal table:
SELECT * FROM high_value_customers
ORDER BY total_spent DESC;


-- Q7: MySQL has no native materialized view. Simulate one by creating a real table that stores the same result as genre_revenue, refreshed on demand instead of live.
CREATE TABLE genre_revenue_snapshot AS
SELECT * FROM genre_revenue;

-- To "refresh" this materialized-view workaround later:
-- TRUNCATE TABLE genre_revenue_snapshot;
-- INSERT INTO genre_revenue_snapshot SELECT * FROM genre_revenue;


-- Q8: Remove a view that's no longer needed.
DROP VIEW IF EXISTS high_value_customers;

-- End of views.sql
