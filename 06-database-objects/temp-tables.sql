-- 06-database-objects / temp-tables.sql
-- Database: Chinook 
-- Note: temporary tables only exist for the current session/connection and are automatically dropped when that connection closes.

USE chinook;

-- Q1: Create a temporary table to hold a filtered snapshot of high-value customers, so it can be queried repeatedly without re-running the full aggregation each time.
CREATE TEMPORARY TABLE temp_high_value_customers AS
SELECT CustomerId, SUM(Total) AS total_spent
FROM invoice
GROUP BY CustomerId
HAVING SUM(Total) > 40;

-- Query it like a normal table:
SELECT * FROM temp_high_value_customers
ORDER BY total_spent DESC;


-- Q2: Create an empty temporary table with an explicit structure, then populate it step by step — useful for staging data before a final calculation.
CREATE TEMPORARY TABLE temp_genre_stats (
    genre_name VARCHAR(120),
    total_tracks INT,
    total_revenue DECIMAL(10,2)
);

INSERT INTO temp_genre_stats (genre_name, total_tracks, total_revenue)
SELECT g.Name,
       COUNT(DISTINCT t.TrackId),
       SUM(il.UnitPrice * il.Quantity)
FROM genre AS g
INNER JOIN track AS t ON g.GenreId = t.GenreId
INNER JOIN invoiceline AS il ON t.TrackId = il.TrackId
GROUP BY g.Name;

-- Query it like a normal table:
SELECT * FROM temp_genre_stats
ORDER BY total_revenue DESC;


-- Q3: Use a temporary table as an intermediate step to simplify a multi-stage calculation — first stage the per-customer spend,then rank it, rather than nesting everything into one query.
CREATE TEMPORARY TABLE temp_customer_spend AS
SELECT CustomerId, SUM(Total) AS total_spent
FROM invoice
GROUP BY CustomerId;

SELECT CustomerId, total_spent,
       RANK() OVER (ORDER BY total_spent DESC) AS spend_rank
FROM temp_customer_spend;


-- Q4: Modify data inside a temporary table directly, the same way you would with a regular table (UPDATE/DELETE both work).
UPDATE temp_genre_stats
SET total_revenue = 0
WHERE total_revenue IS NULL;

DELETE FROM temp_genre_stats
WHERE total_tracks < 5;

SELECT * FROM temp_genre_stats;


-- Q5: Explicitly drop a temporary table before its session end (good practice, rather than relying only on automatic cleanup when the connection closes).
DROP TEMPORARY TABLE IF EXISTS temp_high_value_customers;
DROP TEMPORARY TABLE IF EXISTS temp_genre_stats;
DROP TEMPORARY TABLE IF EXISTS temp_customer_spend;

-- End of temp-tables.sql