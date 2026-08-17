-- =============================================================================================================
-- Star Printers - Enterprise Support Operations Analysis
-- Purpose : Analyze support ticket performance using MySQL
-- Dataset : 500 simulated enterprise support tickets
-- =============================================================================================================

-- =============================================================================================================
-- 1. DATA VALIDATION
-- =============================================================================================================

-- Check total number of tickets.
SELECT COUNT(*) AS Total_Tickets
FROM support_tickets;

-- check number of tickets with missing customer ratings. 
SELECT
    COUNT(*) AS Total_Tickets,
    COUNT(Customer_rating) AS Rated_Tickets,
    COUNT(*) - COUNT(Customer_rating) AS Missing_Ratings
FROM support_tickets;

-- Check unique regions. 
SELECT DISTINCT Region
FROM support_tickets;

-- Check unique priority values. 
SELECT DISTINCT Priority
FROM support_tickets;

-- =============================================================================================================
-- 2. OVERALL KPI ANALYSIS
-- =============================================================================================================

-- Average resolution time 
SELECT
    ROUND(AVG(Resolution_Time), 2) AS Avg_Resolution_Time
FROM support_tickets;

-- Average Customer rating
-- Null ratings are automatically excluded from AVG()
SELECT
    ROUND(AVG(Customer_rating), 2) AS Avg_Customer_Rating
FROM support_tickets;

-- Overall SLA Compliance percentage
SELECT
    ROUND(AVG(CASE WHEN Calculated_SLA = 'Yes' THEN 1 ELSE 0 END) * 100, 2) AS Overall_SLA_Compliance_Percentage
FROM support_tickets;

-- ==============================================================================================================
-- 3. CATEGORY AND DEPARTMENT ANALYSIS
-- ==============================================================================================================

-- Ticket volume by category 
SELECT
    Category,
    COUNT(*) AS Ticket_Count
FROM support_tickets
GROUP BY Category
ORDER BY Ticket_Count DESC;

-- Average resolution time by category 
SELECT
    Category,
    ROUND(AVG(Resolution_Time), 2) AS Avg_Resolution_Time
FROM support_tickets
GROUP BY Category
ORDER BY Avg_Resolution_Time DESC;

-- Ticket workload by department
SELECT
    Department,
    COUNT(*) AS Ticket_Count
FROM support_tickets
GROUP BY Department
ORDER BY Ticket_Count DESC;

-- =============================================================================================================
-- 4. REGIONAL SLA ANALYSIS
-- =============================================================================================================

-- Business Question:
-- How does SLA performance compare across regions?

SELECT
    Region,
    COUNT(*) AS Total_Tickets,
    SUM(CASE WHEN Calculated_SLA = 'Yes' THEN 1 ELSE 0 END) AS SLA_Met_Count,
    SUM(CASE WHEN Calculated_SLA = 'No' THEN 1 ELSE 0 END) AS SLA_Missed_Count,
    ROUND(AVG(CASE WHEN Calculated_SLA = 'Yes' THEN 1 ELSE 0 END) * 100, 2) AS SLA_Compliance_Percentage
FROM support_tickets
GROUP BY Region
ORDER BY SLA_Compliance_Percentage ASC;

-- =============================================================================================================
-- 5. CUSTOMER AND AGENT ANALYSIS
-- =============================================================================================================

-- Business Question:
-- Which customer accounts generate the highest ticket volume?

SELECT
    Account,
    COUNT(*) AS Ticket_Count
FROM support_tickets
GROUP BY Account
ORDER BY Ticket_Count DESC;


-- Business Question:
-- How does average customer satisfaction vary by agent?

SELECT
    Agent,
    ROUND(AVG(Customer_rating), 2) AS Avg_Customer_Rating
FROM support_tickets
GROUP BY Agent
ORDER BY Avg_Customer_Rating DESC;

-- =============================================================================================================
-- 6. MONTHLY TREND ANALYSIS
-- =============================================================================================================

-- Business Question:
-- How did ticket volume and SLA performance change during the reporting period?

SELECT
    MONTHNAME(Created_Date) AS Month_Name,
    COUNT(*) AS Ticket_Count,
    ROUND(AVG(CASE WHEN Calculated_SLA = 'Yes' THEN 1 ELSE 0 END) * 100, 2) AS SLA_Compliance_Percentage
FROM support_tickets
GROUP BY
    MONTH(Created_Date),
    MONTHNAME(Created_Date)
ORDER BY MONTH(Created_Date);

-- =============================================================================================================
-- 7. SUBQUERIES AND CTEs
-- =============================================================================================================

-- Business Question:
-- Which agents have an average customer rating below the overall average customer rating?

SELECT
    Agent,
    ROUND(AVG(Customer_rating), 2) AS Avg_Customer_Rating
FROM support_tickets
GROUP BY Agent
HAVING AVG(Customer_rating) <
(
	SELECT AVG(Customer_rating)
    FROM support_tickets
)
ORDER BY Avg_Customer_Rating ASC;


-- Business Question:
-- Which departments have ticket volume above the average ticket volume across departments?

WITH Department_Volume AS (
    SELECT
        Department,
        COUNT(*) AS Ticket_Volume
    FROM support_tickets
    GROUP BY Department)
SELECT
    Department,
    Ticket_Volume
FROM Department_Volume
WHERE Ticket_Volume > (SELECT AVG(Ticket_Volume) FROM Department_Volume )
ORDER BY Ticket_Volume DESC;

-- ============================================================================================================
-- 8. JOIN ANALYSIS
-- ============================================================================================================

-- Business Question:
-- Match support tickets with available agent details while preserving all support-ticket records.

SELECT
    s.Agent,
    a.Experience_Level,
    COUNT(*) AS Ticket_Count
FROM support_tickets AS s
LEFT JOIN agents AS a
    ON s.Agent = a.Agent
GROUP BY
    s.Agent,
    a.Experience_Level
ORDER BY Ticket_Count DESC;

-- ============================================================================================================
-- 9. DATA QUALITY INVESTIGATION
-- ============================================================================================================

-- Business Question:
-- Which tickets show the largest discrepancy between the supplied Resolution_Time and the elapsed time 
-- calculated from Created_Date and Closed_Date?

SELECT
    Ticket_ID,
    Resolution_Time,
    ROUND(TIMESTAMPDIFF(MINUTE, Created_Date, Closed_Date) / 60.0, 2) AS Calculated_Elapsed_Hours,
    ROUND(Resolution_Time - TIMESTAMPDIFF(MINUTE, Created_Date, Closed_Date) / 60.0, 2) AS Difference
FROM support_tickets
ORDER BY ABS(Resolution_Time - TIMESTAMPDIFF(MINUTE, Created_Date, Closed_Date) / 60.0 ) DESC
LIMIT 10;

-- ============================================================================================================
-- END OF ANALYSIS
-- ============================================================================================================
