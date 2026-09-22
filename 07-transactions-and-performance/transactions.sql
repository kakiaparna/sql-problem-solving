-- 07-transactions-and-performance / transactions.sql
-- Database: Chinook 

USE chinook;

-- Q1: Run a basic transaction — start it, make a change, and commit it permanently.
START TRANSACTION;

UPDATE customer
SET Phone = '+91-9999999999'
WHERE CustomerId = 1;

COMMIT;

-- Verify the change persisted:
SELECT CustomerId, Phone FROM customer WHERE CustomerId = 1;


-- Q2: Start a transaction, make a change, then ROLLBACK instead of committing — the change should NOT persist.
START TRANSACTION;

UPDATE customer
SET Phone = '+91-0000000000'
WHERE CustomerId = 1;

-- Check the value INSIDE the transaction (shows the change):
SELECT CustomerId, Phone FROM customer WHERE CustomerId = 1;

ROLLBACK;

-- Check again AFTER rollback (should show the original Q1 value, not '+91-0000000000'):
SELECT CustomerId, Phone FROM customer WHERE CustomerId = 1;


-- Q3: Use SAVEPOINT to roll back only part of a transaction, instead of the whole thing.
START TRANSACTION;

UPDATE customer SET City = 'Mumbai' WHERE CustomerId = 2;
SAVEPOINT after_city_update;

UPDATE customer SET Country = 'Wrongland' WHERE CustomerId = 2;
-- Realize the Country update was a mistake — undo just that part:
ROLLBACK TO SAVEPOINT after_city_update;

-- City change is kept, Country change is undone:
COMMIT;

SELECT CustomerId, City, Country FROM customer WHERE CustomerId = 2;


-- Q4: Simulate a two-step operation that must succeed or fail together — moving a track from one playlist to another (atomicity: both steps happen, or neither does).
START TRANSACTION;

DELETE FROM playlisttrack
WHERE PlaylistId = 1 AND TrackId = 1;

INSERT INTO playlisttrack (PlaylistId, TrackId)
VALUES (2, 1);

COMMIT;

-- Verify the track moved:
SELECT * FROM playlisttrack WHERE TrackId = 1;


-- Q5: Check and set the transaction isolation level for the current session (controls how much one transaction can see of another transaction's uncommitted changes).
SELECT @@transaction_isolation;

SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

SELECT @@transaction_isolation;


-- Q6: Check the current autocommit setting, then temporarily disable it so multiple statements must be explicitly committed together instead of each one committing automatically.
SELECT @@autocommit;

SET autocommit = 0;

UPDATE customer SET State = 'MH' WHERE CustomerId = 2;
-- With autocommit off, this change is NOT saved until COMMIT runs:
COMMIT;

SET autocommit = 1;


-- Q7: Demonstrate why a transaction matters — deliberately trigger an error mid-transaction and confirm the earlier successful step gets rolled back too (all-or-nothing behavior).
START TRANSACTION;

UPDATE customer SET PostalCode = '400001' WHERE CustomerId = 3;

-- This next statement is intentionally invalid (wrong column name)and will fail — in a real application, catching this error would
-- trigger a ROLLBACK so the PostalCode change above never sticks either. UPDATE customer SET NonExistentColumn = 'x' WHERE CustomerId = 3;

ROLLBACK;

SELECT CustomerId, PostalCode FROM customer WHERE CustomerId = 3;

-- End of transactions.sql
