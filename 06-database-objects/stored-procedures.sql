-- 06-database-objects / stored-procedures.sql
-- Database: Chinook 

USE chinook;

-- Q1: Create a procedure that returns all invoices for a given customer (basic IN parameter).
DELIMITER //
CREATE PROCEDURE GetCustomerInvoices(IN p_customer_id INT)
BEGIN
    SELECT InvoiceId, InvoiceDate, Total
    FROM invoice
    WHERE CustomerId = p_customer_id
    ORDER BY InvoiceDate;
END //
DELIMITER ;

-- Call it:
CALL GetCustomerInvoices(5);


-- Q2: Create a procedure that calculates a customer's total spend and returns it through an OUT parameter instead of a result set.
DELIMITER //
CREATE PROCEDURE GetCustomerTotalSpend(
    IN p_customer_id INT,
    OUT p_total_spent DECIMAL(10,2)
)
BEGIN
    SELECT SUM(Total) INTO p_total_spent
    FROM invoice
    WHERE CustomerId = p_customer_id;
END //
DELIMITER ;

-- Call it:
CALL GetCustomerTotalSpend(5, @total);
SELECT @total AS customer_total_spend;


-- Q3: Create a procedure that classifies a customer into a spending tier using IF/ELSEIF control flow, returned via OUT.
DELIMITER //
CREATE PROCEDURE ClassifyCustomerSpend(
    IN p_customer_id INT,
    OUT p_tier VARCHAR(20)
)
BEGIN
    DECLARE v_total DECIMAL(10,2);

    SELECT SUM(Total) INTO v_total
    FROM invoice
    WHERE CustomerId = p_customer_id;

    IF v_total IS NULL THEN
        SET p_tier = 'No Purchases';
    ELSEIF v_total > 45 THEN
        SET p_tier = 'High Value';
    ELSEIF v_total > 30 THEN
        SET p_tier = 'Medium Value';
    ELSE
        SET p_tier = 'Low Value';
    END IF;
END //
DELIMITER ;

-- Call it:
CALL ClassifyCustomerSpend(5, @tier);
SELECT @tier AS spend_tier;


-- Q4: Create a procedure using a WHILE loop to build a running count from 1 up to a given number.
DELIMITER //
CREATE PROCEDURE CountUpTo(IN p_limit INT)
BEGIN
    DECLARE v_counter INT DEFAULT 1;

    DROP TEMPORARY TABLE IF EXISTS temp_counter;
    CREATE TEMPORARY TABLE temp_counter (num INT);

    WHILE v_counter <= p_limit DO
        INSERT INTO temp_counter VALUES (v_counter);
        SET v_counter = v_counter + 1;
    END WHILE;

    SELECT * FROM temp_counter;
END //
DELIMITER ;

-- Call it:
CALL CountUpTo(5);


-- Q5: Create a procedure using a CURSOR to loop through all employees and build a text summary row by row
DELIMITER //
CREATE PROCEDURE ListEmployeeSummaries()
BEGIN
    DECLARE v_done INT DEFAULT 0;
    DECLARE v_emp_name VARCHAR(100);
    DECLARE v_title VARCHAR(50);

    DECLARE emp_cursor CURSOR FOR
        SELECT CONCAT(FirstName, ' ', LastName), Title
        FROM employee;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    DROP TEMPORARY TABLE IF EXISTS temp_emp_summary;
    CREATE TEMPORARY TABLE temp_emp_summary (summary VARCHAR(200));

    OPEN emp_cursor;

    read_loop: LOOP
        FETCH emp_cursor INTO v_emp_name, v_title;
        IF v_done = 1 THEN
            LEAVE read_loop;
        END IF;
        INSERT INTO temp_emp_summary
        VALUES (CONCAT(v_emp_name, ' - ', v_title));
    END LOOP;

    CLOSE emp_cursor;

    SELECT * FROM temp_emp_summary;
END //
DELIMITER ;

-- Call it:
CALL ListEmployeeSummaries();


-- Q6: Create a procedure with error handling — attempts to insert a new genre, and gracefully reports an error instead of letting the procedure crash if something goes wrong 
DELIMITER //
CREATE PROCEDURE AddGenreSafely(IN p_genre_id INT, IN p_genre_name VARCHAR(120))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'Error: could not insert genre (possibly duplicate ID)' AS result;
    END;

    INSERT INTO genre (GenreId, Name) VALUES (p_genre_id, p_genre_name);
    SELECT 'Genre added successfully' AS result;
END //
DELIMITER ;

-- Call it (try an existing GenreId to see the handler catch the error):
CALL AddGenreSafely(1, 'Test Genre');


-- Q7: Clean up — remove the procedures created in this file.
DROP PROCEDURE IF EXISTS GetCustomerInvoices;
DROP PROCEDURE IF EXISTS GetCustomerTotalSpend;
DROP PROCEDURE IF EXISTS ClassifyCustomerSpend;
DROP PROCEDURE IF EXISTS CountUpTo;
DROP PROCEDURE IF EXISTS ListEmployeeSummaries;
DROP PROCEDURE IF EXISTS AddGenreSafely;

-- End of stored-procedures.sql