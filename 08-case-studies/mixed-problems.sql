-- 08-case-studies / mixed-problems.sql
-- Database: Chinook 

USE chinook;

-- Q1: Who are the top 3 highest-spending customers in each billing country? 
WITH country_customer_spend AS (
    SELECT i.BillingCountry, c.CustomerId,
           CONCAT(c.FirstName, ' ', c.LastName) AS customer_name,
           SUM(i.Total) AS total_spent
    FROM invoice AS i
    INNER JOIN customer AS c ON i.CustomerId = c.CustomerId
    GROUP BY i.BillingCountry, c.CustomerId, c.FirstName, c.LastName
),
ranked_customers AS (
    SELECT BillingCountry, CustomerId, customer_name, total_spent,
           DENSE_RANK() OVER (PARTITION BY BillingCountry ORDER BY total_spent DESC) AS spend_rank
    FROM country_customer_spend
)
SELECT BillingCountry, customer_name, total_spent, spend_rank
FROM ranked_customers
WHERE spend_rank <= 3
ORDER BY BillingCountry, spend_rank;


-- Q2: How is monthly revenue trending — what is the percentage growth or decline compared to the previous month? 
WITH monthly_revenue AS (
    SELECT YEAR(InvoiceDate) AS invoice_year,
           MONTH(InvoiceDate) AS invoice_month,
           SUM(Total) AS revenue
    FROM invoice
    GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate)
)
SELECT invoice_year, invoice_month, revenue,
       LAG(revenue) OVER (ORDER BY invoice_year, invoice_month) AS previous_month_revenue,
       ROUND(
           (revenue - LAG(revenue) OVER (ORDER BY invoice_year, invoice_month))
           / NULLIF(LAG(revenue) OVER (ORDER BY invoice_year, invoice_month), 0) * 100,
           2
       ) AS growth_pct
FROM monthly_revenue
ORDER BY invoice_year, invoice_month;


-- Q3: Which genres sell best in each quarter of the year, to spot seasonality? (multi-table join + conditional aggregation pivot)
SELECT g.Name AS genre_name,
       SUM(CASE WHEN QUARTER(i.InvoiceDate) = 1 THEN il.UnitPrice * il.Quantity ELSE 0 END) AS q1_revenue,
       SUM(CASE WHEN QUARTER(i.InvoiceDate) = 2 THEN il.UnitPrice * il.Quantity ELSE 0 END) AS q2_revenue,
       SUM(CASE WHEN QUARTER(i.InvoiceDate) = 3 THEN il.UnitPrice * il.Quantity ELSE 0 END) AS q3_revenue,
       SUM(CASE WHEN QUARTER(i.InvoiceDate) = 4 THEN il.UnitPrice * il.Quantity ELSE 0 END) AS q4_revenue
FROM invoiceline AS il
INNER JOIN invoice AS i ON il.InvoiceId = i.InvoiceId
INNER JOIN track AS t ON il.TrackId = t.TrackId
INNER JOIN genre AS g ON t.GenreId = g.GenreId
GROUP BY g.Name
ORDER BY SUM(il.UnitPrice * il.Quantity) DESC;


-- Q4: Which customers spend more than the average customer in their own country, and by how much? (CTE + window AVG with PARTITION BY)
WITH country_customer_spend AS (
    SELECT i.BillingCountry, c.CustomerId,
           CONCAT(c.FirstName, ' ', c.LastName) AS customer_name,
           SUM(i.Total) AS total_spent
    FROM invoice AS i
    INNER JOIN customer AS c ON i.CustomerId = c.CustomerId
    GROUP BY i.BillingCountry, c.CustomerId, c.FirstName, c.LastName
),
compared AS (
    SELECT BillingCountry, customer_name, total_spent,
           AVG(total_spent) OVER (PARTITION BY BillingCountry) AS country_avg
    FROM country_customer_spend
)
SELECT BillingCountry, customer_name, total_spent,
       ROUND(country_avg, 2) AS country_avg,
       ROUND(total_spent - country_avg, 2) AS above_avg_by
FROM compared
WHERE total_spent > country_avg
ORDER BY above_avg_by DESC;


-- Q5: Which artists in the catalog have never sold a single track? 
SELECT ar.ArtistId, ar.Name AS artist_name
FROM artist AS ar
WHERE NOT EXISTS (
    SELECT 1
    FROM album AS al
    INNER JOIN track AS t ON al.AlbumId = t.AlbumId
    INNER JOIN invoiceline AS il ON t.TrackId = il.TrackId
    WHERE al.ArtistId = ar.ArtistId
)
ORDER BY ar.Name;


-- Q6: How adventurous is each customer's taste — how many distinct genres have they bought, and what type of listener are they?
SELECT c.CustomerId,
       CONCAT(c.FirstName, ' ', c.LastName) AS customer_name,
       COUNT(DISTINCT t.GenreId) AS distinct_genres,
       CASE
           WHEN COUNT(DISTINCT t.GenreId) >= 10 THEN 'Explorer'
           WHEN COUNT(DISTINCT t.GenreId) >= 6 THEN 'Regular'
           ELSE 'Focused'
       END AS listener_type
FROM customer AS c
INNER JOIN invoice AS i ON c.CustomerId = i.CustomerId
INNER JOIN invoiceline AS il ON i.InvoiceId = il.InvoiceId
INNER JOIN track AS t ON il.TrackId = t.TrackId
GROUP BY c.CustomerId, c.FirstName, c.LastName
ORDER BY distinct_genres DESC;


-- Q7: How much of total revenue does each support rep bring in, and how do they rank? 
WITH rep_revenue AS (
    SELECT e.EmployeeId,
           CONCAT(e.FirstName, ' ', e.LastName) AS rep_name,
           SUM(i.Total) AS revenue
    FROM employee AS e
    INNER JOIN customer AS c ON e.EmployeeId = c.SupportRepId
    INNER JOIN invoice AS i ON c.CustomerId = i.CustomerId
    GROUP BY e.EmployeeId, e.FirstName, e.LastName
)
SELECT rep_name, revenue,
       ROUND(revenue / SUM(revenue) OVER () * 100, 2) AS pct_of_total_revenue,
       RANK() OVER (ORDER BY revenue DESC) AS revenue_rank
FROM rep_revenue;


-- Q8: How often does each customer come back to buy — what is the average number of days between their consecutive purchases?
WITH purchase_gaps AS (
    SELECT CustomerId, InvoiceDate,
           DATEDIFF(
               InvoiceDate,
               LAG(InvoiceDate) OVER (PARTITION BY CustomerId ORDER BY InvoiceDate)
           ) AS days_since_previous
    FROM invoice
)
SELECT CustomerId,
       ROUND(AVG(days_since_previous), 1) AS avg_days_between_purchases,
       COUNT(days_since_previous) AS gaps_measured
FROM purchase_gaps
GROUP BY CustomerId
HAVING COUNT(days_since_previous) > 0
ORDER BY avg_days_between_purchases;


-- Q9: What is the best-selling track on each album? 
WITH track_sales AS (
    SELECT al.AlbumId, al.Title AS album_title,
           t.TrackId, t.Name AS track_name,
           SUM(il.UnitPrice * il.Quantity) AS revenue
    FROM album AS al
    INNER JOIN track AS t ON al.AlbumId = t.AlbumId
    INNER JOIN invoiceline AS il ON t.TrackId = il.TrackId
    GROUP BY al.AlbumId, al.Title, t.TrackId, t.Name
),
ranked_tracks AS (
    SELECT AlbumId, album_title, track_name, revenue,
           ROW_NUMBER() OVER (PARTITION BY AlbumId ORDER BY revenue DESC, TrackId) AS rn
    FROM track_sales
)
SELECT album_title, track_name, revenue
FROM ranked_tracks
WHERE rn = 1
ORDER BY revenue DESC
LIMIT 20;


-- Q10: What is the total revenue managed by each employee, counting their own customers plus everyone who reports to them, directly or indirectly? 
WITH RECURSIVE all_subordinates AS (
    SELECT EmployeeId AS manager_id, EmployeeId AS subordinate_id
    FROM employee

    UNION ALL

    SELECT a.manager_id, e.EmployeeId
    FROM employee AS e
    INNER JOIN all_subordinates AS a ON e.ReportsTo = a.subordinate_id
),
rep_revenue AS (
    SELECT c.SupportRepId, SUM(i.Total) AS revenue
    FROM customer AS c
    INNER JOIN invoice AS i ON c.CustomerId = i.CustomerId
    GROUP BY c.SupportRepId
)
SELECT m.EmployeeId,
       CONCAT(m.FirstName, ' ', m.LastName) AS manager_name,
       m.Title,
       ROUND(SUM(COALESCE(rr.revenue, 0)), 2) AS team_revenue
FROM all_subordinates AS a
INNER JOIN employee AS m ON a.manager_id = m.EmployeeId
LEFT JOIN rep_revenue AS rr ON a.subordinate_id = rr.SupportRepId
GROUP BY m.EmployeeId, m.FirstName, m.LastName, m.Title
ORDER BY team_revenue DESC;


-- Q11: Which customers have bought Rock tracks but never a Jazz track, as targets for a Jazz promotion? 
WITH rock_not_jazz AS (
    SELECT DISTINCT i.CustomerId
    FROM invoice AS i
    INNER JOIN invoiceline AS il ON i.InvoiceId = il.InvoiceId
    INNER JOIN track AS t ON il.TrackId = t.TrackId
    INNER JOIN genre AS g ON t.GenreId = g.GenreId
    WHERE g.Name = 'Rock'

    EXCEPT

    SELECT DISTINCT i.CustomerId
    FROM invoice AS i
    INNER JOIN invoiceline AS il ON i.InvoiceId = il.InvoiceId
    INNER JOIN track AS t ON il.TrackId = t.TrackId
    INNER JOIN genre AS g ON t.GenreId = g.GenreId
    WHERE g.Name = 'Jazz'
)
SELECT c.CustomerId, c.FirstName, c.LastName, c.Email
FROM customer AS c
INNER JOIN rock_not_jazz AS r ON c.CustomerId = r.CustomerId
ORDER BY c.CustomerId;

-- End of mixed-problems.sql
