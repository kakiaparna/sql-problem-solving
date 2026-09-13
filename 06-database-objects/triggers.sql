-- 06-database-objects / triggers.sql
-- Database: Chinook 

USE chinook;

-- Setup: audit tables used by the triggers below.
CREATE TABLE IF NOT EXISTS customer_audit_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    action VARCHAR(20),
    action_time DATETIME
);

CREATE TABLE IF NOT EXISTS invoice_price_changes (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_id INT,
    old_total DECIMAL(10,2),
    new_total DECIMAL(10,2),
    changed_at DATETIME
);


-- Q1: BEFORE INSERT — automatically trim any accidental leading/trailing spaces from a new customer's email before it's saved.
DELIMITER //
CREATE TRIGGER trg_customer_before_insert
BEFORE INSERT ON customer
FOR EACH ROW
BEGIN
    SET NEW.Email = TRIM(NEW.Email);
END //
DELIMITER ;


-- Q2: AFTER INSERT — log every new customer signup into an audit table automatically, without changing application code.
DELIMITER //
CREATE TRIGGER trg_customer_after_insert
AFTER INSERT ON customer
FOR EACH ROW
BEGIN
    INSERT INTO customer_audit_log (customer_id, action, action_time)
    VALUES (NEW.CustomerId, 'INSERTED', NOW());
END //
DELIMITER ;


-- Q3: BEFORE UPDATE — prevent a track's UnitPrice from ever being updated to a negative value, using SIGNAL to raise an error.
DELIMITER //
CREATE TRIGGER trg_track_before_update
BEFORE UPDATE ON track
FOR EACH ROW
BEGIN
    IF NEW.UnitPrice < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'UnitPrice cannot be negative';
    END IF;
END //
DELIMITER ;


-- Q4: AFTER UPDATE — whenever an invoice's Total is changed, automatically log the old and new value for auditing.
DELIMITER //
CREATE TRIGGER trg_invoice_after_update
AFTER UPDATE ON invoice
FOR EACH ROW
BEGIN
    IF OLD.Total <> NEW.Total THEN
        INSERT INTO invoice_price_changes (invoice_id, old_total, new_total, changed_at)
        VALUES (OLD.InvoiceId, OLD.Total, NEW.Total, NOW());
    END IF;
END //
DELIMITER ;


-- Q5: BEFORE DELETE — block deletion of a customer who still has existing invoices, instead of silently allowing orphaned data.
DELIMITER //
CREATE TRIGGER trg_customer_before_delete
BEFORE DELETE ON customer
FOR EACH ROW
BEGIN
    DECLARE v_invoice_count INT;

    SELECT COUNT(*) INTO v_invoice_count
    FROM invoice
    WHERE CustomerId = OLD.CustomerId;

    IF v_invoice_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot delete customer with existing invoices';
    END IF;
END //
DELIMITER ;


-- Q6: AFTER DELETE — log any customer that IS successfully deleted (one with no invoices) into the same audit table.
DELIMITER //
CREATE TRIGGER trg_customer_after_delete
AFTER DELETE ON customer
FOR EACH ROW
BEGIN
    INSERT INTO customer_audit_log (customer_id, action, action_time)
    VALUES (OLD.CustomerId, 'DELETED', NOW());
END //
DELIMITER ;


-- Test Q3's trigger — this should fail with the custom error message:UPDATE track SET UnitPrice = -5 WHERE TrackId = 1;

-- Test Q5's trigger — this should fail since customer 5 has invoices:DELETE FROM customer WHERE CustomerId = 5;


-- Q7: Clean up — remove the triggers created in this file.
DROP TRIGGER IF EXISTS trg_customer_before_insert;
DROP TRIGGER IF EXISTS trg_customer_after_insert;
DROP TRIGGER IF EXISTS trg_track_before_update;
DROP TRIGGER IF EXISTS trg_invoice_after_update;
DROP TRIGGER IF EXISTS trg_customer_before_delete;
DROP TRIGGER IF EXISTS trg_customer_after_delete;

-- End of triggers.sql
DELIMITER //
CREATE TRIGGER trg_customer_before_insert
BEFORE INSERT ON customer
FOR EACH ROW
BEGIN
    SET NEW.Email = TRIM(NEW.Email);
END //
DELIMITER ;

SHOW TRIGGERS FROM chinook;

-- Test 1: BEFORE INSERT (email trim) + AFTER INSERT (audit log)
INSERT INTO customer (CustomerId, FirstName, LastName, Email)
VALUES (9998, 'Test', 'User2', '  test2@example.com  ');

SELECT * FROM customer_audit_log WHERE customer_id = 9998;
SELECT Email FROM customer WHERE CustomerId = 9998;