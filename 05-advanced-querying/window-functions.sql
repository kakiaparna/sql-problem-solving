-- 05-advanced-querying / window-functions.sql
-- Database: Chinook 

USE chinook;

-- Q1: Rank every customer by total spend, using ROW_NUMBER, RANK, and DENSE_RANK side by side to see how each handles ties differently.
WITH customer_spend AS (
    SELECT CustomerId, SUM(Total) AS total_spent
    FROM invoice
    GROUP BY CustomerId
)
SELECT CustomerId, total_spent,
       ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS row_num,
       RANK()       OVER (ORDER BY total_spent DESC) AS rank_num,
       DENSE_RANK() OVER (ORDER BY total_spent DESC) AS dense_rank_num
FROM customer_spend
ORDER BY total_spent DESC;


-- Q2: Within each genre, rank tracks by unit price from highest to lowest (PARTITION BY resets the ranking per group).
SELECT t.TrackId, t.Name AS track_name, g.Name AS genre_name, t.UnitPrice,
       RANK() OVER (PARTITION BY g.GenreId ORDER BY t.UnitPrice DESC) AS price_rank_in_genre
FROM track AS t
INNER JOIN genre AS g ON t.GenreId = g.GenreId;


-- Q3: For each customer, compare each invoice's total to their previous invoice's total (LAG).
SELECT CustomerId, InvoiceId, InvoiceDate, Total,
       LAG(Total) OVER (PARTITION BY CustomerId ORDER BY InvoiceDate) AS previous_invoice_total,
       Total - LAG(Total) OVER (PARTITION BY CustomerId ORDER BY InvoiceDate) AS change_from_previous
FROM invoice
ORDER BY CustomerId, InvoiceDate;


-- Q4: For each customer, find how many days passed until their NEXT invoice (LEAD), to see purchase frequency.
SELECT CustomerId, InvoiceId, InvoiceDate,
       LEAD(InvoiceDate) OVER (PARTITION BY CustomerId ORDER BY InvoiceDate) AS next_invoice_date,
       DATEDIFF(
           LEAD(InvoiceDate) OVER (PARTITION BY CustomerId ORDER BY InvoiceDate),
           InvoiceDate
       ) AS days_until_next_purchase
FROM invoice
ORDER BY CustomerId, InvoiceDate;


-- Q5: Calculate each customer's running (cumulative) total spend over time, ordered by invoice date.
SELECT CustomerId, InvoiceId, InvoiceDate, Total,
       SUM(Total) OVER (PARTITION BY CustomerId ORDER BY InvoiceDate
                         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM invoice
ORDER BY CustomerId, InvoiceDate;


-- Q6: Calculate a 3-invoice moving average of invoice totals for each customer, to smooth out spend spikes.
SELECT CustomerId, InvoiceId, InvoiceDate, Total,
       AVG(Total) OVER (PARTITION BY CustomerId ORDER BY InvoiceDate
                         ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3_invoices
FROM invoice
ORDER BY CustomerId, InvoiceDate;


-- Q7: Split all customers into 4 equal-sized spending groups (quartiles), from highest spenders to lowest (NTILE).
WITH customer_spend AS (
    SELECT CustomerId, SUM(Total) AS total_spent
    FROM invoice
    GROUP BY CustomerId
)
SELECT CustomerId, total_spent,
       NTILE(4) OVER (ORDER BY total_spent DESC) AS spending_quartile
FROM customer_spend;


-- Q8: For each customer, show their first-ever invoice total and their most recent invoice total side by side (FIRST_VALUE / LAST_VALUE).
SELECT DISTINCT CustomerId,
       FIRST_VALUE(Total) OVER (PARTITION BY CustomerId ORDER BY InvoiceDate
                                 ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS first_invoice_total,
       LAST_VALUE(Total) OVER (PARTITION BY CustomerId ORDER BY InvoiceDate
                                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS latest_invoice_total
FROM invoice;


-- Q9: Find the top 3 highest-grossing tracks within each genre (classic "top N per group" pattern, using ROW_NUMBER + PARTITION BY inside a CTE, then filtering in the outer query).
WITH track_genre_revenue AS (
    SELECT g.Name AS genre_name, t.Name AS track_name,
           SUM(il.UnitPrice * il.Quantity) AS revenue,
           ROW_NUMBER() OVER (PARTITION BY g.GenreId ORDER BY SUM(il.UnitPrice * il.Quantity) DESC) AS rn
    FROM invoiceline AS il
    INNER JOIN track AS t ON il.TrackId = t.TrackId
    INNER JOIN genre AS g ON t.GenreId = g.GenreId
    GROUP BY g.GenreId, g.Name, t.TrackId, t.Name
)
SELECT genre_name, track_name, revenue
FROM track_genre_revenue
WHERE rn <= 3
ORDER BY genre_name, revenue DESC;


-- Q10: For each customer, calculate what percentage of their total lifetime spend each individual invoice represents.
SELECT CustomerId, InvoiceId, Total,
       ROUND(Total / SUM(Total) OVER (PARTITION BY CustomerId) * 100, 2) AS pct_of_customer_total
FROM invoice
ORDER BY CustomerId, InvoiceId;


-- Q11: Rank employees by total revenue generated through the customers they support, without partitioning (single global ranking).
WITH rep_revenue AS (
    SELECT e.EmployeeId, CONCAT(e.FirstName, ' ', e.LastName) AS employee_name,
           SUM(i.Total) AS total_revenue
    FROM employee AS e
    INNER JOIN customer AS c ON e.EmployeeId = c.SupportRepId
    INNER JOIN invoice AS i ON c.CustomerId = i.CustomerId
    GROUP BY e.EmployeeId, e.FirstName, e.LastName
)
SELECT employee_name, total_revenue,
       RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM rep_revenue;


-- Q12: For each genre, find the difference between each track's price and the average price within that same genre.
SELECT t.TrackId, t.Name AS track_name, g.Name AS genre_name, t.UnitPrice,
       ROUND(AVG(t.UnitPrice) OVER (PARTITION BY g.GenreId), 2) AS genre_avg_price,
       ROUND(t.UnitPrice - AVG(t.UnitPrice) OVER (PARTITION BY g.GenreId), 2) AS diff_from_genre_avg
FROM track AS t
INNER JOIN genre AS g ON t.GenreId = g.GenreId;

-- End of window-functions.sql