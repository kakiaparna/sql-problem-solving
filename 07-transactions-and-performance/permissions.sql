-- SQL Problem Solving
-- 07-transactions-and-performance / permissions.sql
-- Database: Chinook | MySQL 8.0.42
-- Note: requires an admin account (e.g. root) to run CREATE USER /
-- GRANT / REVOKE. Passwords below are placeholders for local practice only.
-- Each privilege level uses its own user, since MySQL privileges are
-- additive: a broader grant would make a narrower one meaningless.

USE chinook;

-- Q1: Create a limited-privilege user for an analyst who should
-- only be able to read data, never modify it.
CREATE USER IF NOT EXISTS 'analyst_readonly'@'localhost'
IDENTIFIED BY 'placeholder_pw_1';


-- Q2: Grant read-only access to a single table, not the whole
-- database — the most restrictive, safest level of access.
GRANT SELECT ON chinook.customer TO 'analyst_readonly'@'localhost';


-- Q3: Create an application service account that needs to read
-- AND write across the whole database, and grant multiple
-- privileges at once at database level.
CREATE USER IF NOT EXISTS 'app_service'@'localhost'
IDENTIFIED BY 'placeholder_pw_2';

GRANT SELECT, INSERT, UPDATE ON chinook.* TO 'app_service'@'localhost';


-- Q4: Create a user who can see only specific columns of a table
-- (names, but not contact details) using column-level privileges.
CREATE USER IF NOT EXISTS 'analyst_limited'@'localhost'
IDENTIFIED BY 'placeholder_pw_3';

GRANT SELECT (CustomerId, FirstName, LastName)
ON chinook.customer
TO 'analyst_limited'@'localhost';


-- Q5: Check exactly what privileges each user currently has.
SHOW GRANTS FOR 'analyst_readonly'@'localhost';
SHOW GRANTS FOR 'app_service'@'localhost';
SHOW GRANTS FOR 'analyst_limited'@'localhost';


-- Q6: Remove a specific privilege without deleting the user —
-- e.g., revoke write access if the service account no longer
-- needs to INSERT.
REVOKE INSERT ON chinook.* FROM 'app_service'@'localhost';

-- Confirm the change:
SHOW GRANTS FOR 'app_service'@'localhost';


-- Q7: Remove users entirely, along with all of their privileges
-- (cleanup).
DROP USER IF EXISTS 'analyst_readonly'@'localhost';
DROP USER IF EXISTS 'app_service'@'localhost';
DROP USER IF EXISTS 'analyst_limited'@'localhost';


CREATE USER 'app_service'@'localhost' IDENTIFIED BY 'placeholder_pw_2';
GRANT SELECT, INSERT, UPDATE ON chinook.* TO 'app_service'@'localhost';

SHOW GRANTS FOR 'app_service'@'localhost';
REVOKE INSERT ON chinook.* FROM 'app_service'@'localhost';
SHOW GRANTS FOR 'app_service'@'localhost';

DROP USER IF EXISTS 'app_service'@'localhost';

SELECT user, host FROM mysql.user
WHERE user IN ('analyst_readonly', 'app_service', 'analyst_limited');
-- End of permissions.sql