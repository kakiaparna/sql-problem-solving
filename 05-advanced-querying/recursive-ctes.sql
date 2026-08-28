-- 05-advanced-querying / recursive-ctes.sql
-- Database: Chinook 

USE chinook;

-- Q1: Build the full company org chart, starting from the top (the employee who reports to no one).
WITH RECURSIVE org_chart AS (
    SELECT EmployeeId, FirstName, LastName, Title, ReportsTo, 1 AS level
    FROM employee
    WHERE ReportsTo IS NULL

    UNION ALL

    SELECT e.EmployeeId, e.FirstName, e.LastName, e.Title, e.ReportsTo,
           oc.level + 1
    FROM employee AS e
    INNER JOIN org_chart AS oc ON e.ReportsTo = oc.EmployeeId
)
SELECT * FROM org_chart
ORDER BY level, EmployeeId;


-- Q2: Find every employee who reports to a given manager, either directly or through the chain (all subordinates under EmployeeId 2).
WITH RECURSIVE subordinates AS (
    SELECT EmployeeId, FirstName, LastName, ReportsTo
    FROM employee
    WHERE ReportsTo = 2

    UNION ALL

    SELECT e.EmployeeId, e.FirstName, e.LastName, e.ReportsTo
    FROM employee AS e
    INNER JOIN subordinates AS s ON e.ReportsTo = s.EmployeeId
)
SELECT * FROM subordinates;


-- Q3: For a given employee (EmployeeId 8), trace the full chain of managers above them, all the way up to the top of the company.
WITH RECURSIVE management_chain AS (
    SELECT EmployeeId, FirstName, LastName, ReportsTo, 1 AS step_up
    FROM employee
    WHERE EmployeeId = 8

    UNION ALL

    SELECT e.EmployeeId, e.FirstName, e.LastName, e.ReportsTo,
           mc.step_up + 1
    FROM employee AS e
    INNER JOIN management_chain AS mc ON e.EmployeeId = mc.ReportsTo
)
SELECT * FROM management_chain
ORDER BY step_up DESC;


-- Q4: For every employee, calculate how many levels deep they sit in the org hierarchy (1 = top, 2 = reports to top, etc.).
WITH RECURSIVE hierarchy_depth AS (
    SELECT EmployeeId, FirstName, LastName, ReportsTo, 1 AS depth
    FROM employee
    WHERE ReportsTo IS NULL

    UNION ALL

    SELECT e.EmployeeId, e.FirstName, e.LastName, e.ReportsTo,
           hd.depth + 1
    FROM employee AS e
    INNER JOIN hierarchy_depth AS hd ON e.ReportsTo = hd.EmployeeId
)
SELECT * FROM hierarchy_depth
ORDER BY depth, EmployeeId;


-- Q5: For each manager, count their total number of subordinates direct reports plus everyone further down that branch.
WITH RECURSIVE all_subordinates AS (
    SELECT EmployeeId AS manager_id, EmployeeId AS subordinate_id
    FROM employee

    UNION ALL

    SELECT a.manager_id, e.EmployeeId
    FROM employee AS e
    INNER JOIN all_subordinates AS a ON e.ReportsTo = a.subordinate_id
)
SELECT manager_id, COUNT(*) - 1 AS total_subordinates
FROM all_subordinates
GROUP BY manager_id
HAVING COUNT(*) - 1 > 0
ORDER BY total_subordinates DESC;

-- End of recursive-ctes.sql