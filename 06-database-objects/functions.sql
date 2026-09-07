-- 06-database-objects / functions.sql
-- Database: Chinook

USE chinook;

-- Q1: Create a function that returns a customer's full name as one string, so it can be reused inline in any SELECT.
DELIMITER //
CREATE FUNCTION GetFullName(p_first VARCHAR(40), p_last VARCHAR(40))
RETURNS VARCHAR(81)
DETERMINISTIC
BEGIN
    RETURN CONCAT(p_first, ' ', p_last);
END //
DELIMITER ;

-- Use it:
SELECT CustomerId, GetFullName(FirstName, LastName) AS full_name
FROM customer;


-- Q2: Create a function that converts a track's length from milliseconds into a readable "minutes:seconds" format.
DELIMITER //
CREATE FUNCTION FormatDuration(p_milliseconds INT)
RETURNS VARCHAR(10)
DETERMINISTIC
BEGIN
    DECLARE v_total_seconds INT;
    DECLARE v_minutes INT;
    DECLARE v_seconds INT;

    SET v_total_seconds = p_milliseconds DIV 1000;
    SET v_minutes = v_total_seconds DIV 60;
    SET v_seconds = v_total_seconds MOD 60;

    RETURN CONCAT(v_minutes, ':', LPAD(v_seconds, 2, '0'));
END //
DELIMITER ;

-- Use it:
SELECT TrackId, Name, Milliseconds, FormatDuration(Milliseconds) AS duration
FROM track;


-- Q3: Create a function that classifies a track as 'Short', 'Medium', or 'Long' based on its length — reusable logic instead of repeating a CASE expression in every query.
DELIMITER //
CREATE FUNCTION ClassifyTrackLength(p_milliseconds INT)
RETURNS VARCHAR(10)
DETERMINISTIC
BEGIN
    DECLARE v_minutes DECIMAL(10,2);
    SET v_minutes = p_milliseconds / 60000;

    IF v_minutes < 3 THEN
        RETURN 'Short';
    ELSEIF v_minutes <= 6 THEN
        RETURN 'Medium';
    ELSE
        RETURN 'Long';
    END IF;
END //
DELIMITER ;

-- Use it:
SELECT TrackId, Name, Milliseconds, ClassifyTrackLength(Milliseconds) AS length_category
FROM track;


-- Q4: Create a function that queries the invoice table to return a customer's total spend — callable directly inside a SELECT, unlike a stored procedure which can't be used this way.
DELIMITER //
CREATE FUNCTION GetCustomerTotalSpend(p_customer_id INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(10,2);
    SELECT SUM(Total) INTO v_total
    FROM invoice
    WHERE CustomerId = p_customer_id;

    RETURN IFNULL(v_total, 0);
END //
DELIMITER ;

-- Use it directly inline, unlike a procedure:
SELECT CustomerId, GetFullName(FirstName, LastName) AS full_name,
       GetCustomerTotalSpend(CustomerId) AS total_spent
FROM customer
ORDER BY total_spent DESC;


-- Q5: Use a function inside a WHERE clause to filter customers whose total spend exceeds a threshold — showing that functions, unlike procedures, can be used anywhere an expression is allowed.
SELECT CustomerId, GetFullName(FirstName, LastName) AS full_name
FROM customer
WHERE GetCustomerTotalSpend(CustomerId) > 40;


-- Q6: Create a function that applies a discount percentage to a price and rounds the result — a small reusable calculation
DELIMITER //
CREATE FUNCTION ApplyDiscount(p_price DECIMAL(10,2), p_discount_pct DECIMAL(5,2))
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    RETURN ROUND(p_price - (p_price * p_discount_pct / 100), 2);
END //
DELIMITER ;

-- Use it:
SELECT TrackId, Name, UnitPrice,
       ApplyDiscount(UnitPrice, 10) AS price_after_10pct_discount
FROM track;


-- Q7: Clean up — remove the functions created in this file.
DROP FUNCTION IF EXISTS GetFullName;
DROP FUNCTION IF EXISTS FormatDuration;
DROP FUNCTION IF EXISTS ClassifyTrackLength;
DROP FUNCTION IF EXISTS GetCustomerTotalSpend;
DROP FUNCTION IF EXISTS ApplyDiscount;

-- End of functions.sql