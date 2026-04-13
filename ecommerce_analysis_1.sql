-- ============================================================
-- Task 3: SQL for Data Analysis
-- Dataset: E-Commerce Orders (541,909 rows)
-- Tool: SQLite  |  Columns: InvoiceNo, StockCode, Description,
--               Quantity, InvoiceDate, UnitPrice, CustomerID,
--               Country, Revenue (Quantity * UnitPrice)
-- ============================================================


-- ============================================================
-- 1. BASIC SELECT + WHERE + ORDER BY
-- ============================================================
-- Get orders from Germany where revenue > 50
SELECT InvoiceNo, Description, Quantity, UnitPrice, Revenue
FROM orders
WHERE Country = 'Germany' AND Revenue > 50
ORDER BY Revenue DESC
LIMIT 10;


-- ============================================================
-- 2. GROUP BY + Aggregate Functions (SUM, AVG, COUNT)
-- ============================================================
SELECT
    Country,
    COUNT(*)               AS TotalOrders,
    ROUND(SUM(Revenue), 2) AS TotalRevenue,
    ROUND(AVG(Revenue), 2) AS AvgOrderRevenue
FROM orders
GROUP BY Country
ORDER BY TotalRevenue DESC
LIMIT 10;


-- ============================================================
-- 3. WHERE vs HAVING
--    WHERE  → filters individual rows BEFORE grouping
--    HAVING → filters grouped results AFTER aggregation
-- ============================================================
SELECT
    Country,
    ROUND(SUM(Revenue), 2) AS TotalRevenue
FROM orders
WHERE Quantity > 0                    -- row-level filter
GROUP BY Country
HAVING TotalRevenue > 100000          -- group-level filter
ORDER BY TotalRevenue DESC;


-- ============================================================
-- 4. Average Revenue Per User (ARPU)
-- ============================================================
SELECT
    ROUND(SUM(Revenue) / COUNT(DISTINCT CustomerID), 2) AS AvgRevenuePerUser
FROM orders
WHERE CustomerID IS NOT NULL;


-- ============================================================
-- 5a. INNER JOIN – Top customers with more than 5 orders
-- ============================================================
SELECT
    o.CustomerID,
    o.Country,
    c.TotalOrders,
    ROUND(SUM(o.Revenue), 2) AS TotalSpend
FROM orders o
INNER JOIN (
    SELECT CustomerID, COUNT(DISTINCT InvoiceNo) AS TotalOrders
    FROM orders
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
    HAVING TotalOrders > 5
) c ON o.CustomerID = c.CustomerID
GROUP BY o.CustomerID
ORDER BY TotalSpend DESC
LIMIT 10;


-- ============================================================
-- 5b. LEFT JOIN – All products including those with no positive sales
-- ============================================================
SELECT
    a.Description,
    COALESCE(b.TotalSold, 0) AS TotalSold
FROM orders a
LEFT JOIN (
    SELECT Description, SUM(Quantity) AS TotalSold
    FROM orders
    WHERE Quantity > 0
    GROUP BY Description
) b ON a.Description = b.Description
GROUP BY a.Description
ORDER BY TotalSold DESC
LIMIT 10;


-- ============================================================
-- 6. SUBQUERY – Orders where revenue > average revenue
-- ============================================================
SELECT InvoiceNo, Description, ROUND(Revenue, 2) AS Revenue
FROM orders
WHERE Revenue > (
    SELECT AVG(Revenue) FROM orders WHERE Revenue > 0
)
ORDER BY Revenue DESC
LIMIT 10;

-- Subquery: Top-selling product per country (using window function)
SELECT Country, Description, TotalQty
FROM (
    SELECT
        Country,
        Description,
        SUM(Quantity) AS TotalQty,
        RANK() OVER (PARTITION BY Country ORDER BY SUM(Quantity) DESC) AS rnk
    FROM orders
    WHERE Quantity > 0
    GROUP BY Country, Description
) ranked
WHERE rnk = 1
ORDER BY TotalQty DESC
LIMIT 10;


-- ============================================================
-- 7. NULL VALUE HANDLING
-- ============================================================
-- Count missing CustomerIDs
SELECT COUNT(*) AS NullCustomers
FROM orders
WHERE CustomerID IS NULL;

-- Replace NULL with 'Guest' using COALESCE
SELECT
    COALESCE(CustomerID, 'Guest') AS CustomerID,
    COUNT(*)                      AS Orders,
    ROUND(SUM(Revenue), 2)        AS Revenue
FROM orders
GROUP BY COALESCE(CustomerID, 'Guest')
ORDER BY Revenue DESC
LIMIT 10;


-- ============================================================
-- 8. CREATE VIEW for reusable analysis
-- ============================================================
DROP VIEW IF EXISTS customer_revenue_summary;

CREATE VIEW customer_revenue_summary AS
SELECT
    CustomerID,
    Country,
    COUNT(DISTINCT InvoiceNo)      AS TotalInvoices,
    ROUND(SUM(Revenue), 2)         AS TotalRevenue,
    ROUND(AVG(Revenue), 2)         AS AvgOrderValue,
    MAX(InvoiceDate)               AS LastOrderDate
FROM orders
WHERE CustomerID IS NOT NULL
  AND Quantity > 0
GROUP BY CustomerID;

-- Query the view
SELECT * FROM customer_revenue_summary
ORDER BY TotalRevenue DESC
LIMIT 10;


-- ============================================================
-- 9. INDEXES for Query Optimization
--    Without index: full table scan of 541k rows
--    With index:    direct lookup — much faster
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_customer  ON orders(CustomerID);
CREATE INDEX IF NOT EXISTS idx_country   ON orders(Country);
CREATE INDEX IF NOT EXISTS idx_invoiceno ON orders(InvoiceNo);

-- Optimized lookup using index
SELECT CustomerID, ROUND(SUM(Revenue), 2) AS TotalRevenue
FROM orders
WHERE CustomerID = '17850'
GROUP BY CustomerID;


-- ============================================================
-- 10. BONUS: Monthly Revenue Trend
-- ============================================================
SELECT
    SUBSTR(InvoiceDate, 1, 7)      AS Month,
    ROUND(SUM(Revenue), 2)         AS MonthlyRevenue,
    COUNT(DISTINCT CustomerID)     AS UniqueCustomers
FROM orders
WHERE Quantity > 0
GROUP BY Month
ORDER BY Month;
