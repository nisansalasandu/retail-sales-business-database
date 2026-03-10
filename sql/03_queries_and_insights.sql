

USE RetailSalesDataBase;
GO

-- ============================================================
--  SECTION A — DATABASE OVERVIEW
--  To confirm data loaded correctly
-- ============================================================

-- A1. Row count of every table
-- Shows how many records exist in each table
SELECT 'Customers'    AS TableName, COUNT(*) AS TotalRows FROM dbo.Customers    UNION ALL
SELECT 'Products'     AS TableName, COUNT(*) AS TotalRows FROM dbo.Products     UNION ALL
SELECT 'Stores'       AS TableName, COUNT(*) AS TotalRows FROM dbo.Stores       UNION ALL
SELECT 'Transactions' AS TableName, COUNT(*) AS TotalRows FROM dbo.Transactions;
GO

-- A2. Full preview of all lookup tables
SELECT * FROM dbo.Stores;
SELECT * FROM dbo.Products ORDER BY Category, SubCategory;
GO

-- A3. Sample of transactions joined with all related tables
-- Combines all 4 tables into one readable result
SELECT TOP 10
    t.TransactionID,
    t.Date,
    c.FullName          AS CustomerName,
    c.Gender,
    c.City              AS CustomerCity,
    p.ProductName,
    p.Category,
    p.SubCategory,
    s.StoreName,
    s.Region,
    t.Quantity,
    t.Discount,
    t.PaymentMethod,
    t.TotalAmount
FROM       dbo.Transactions t
INNER JOIN dbo.Customers    c ON t.CustomerID = c.CustomerID
INNER JOIN dbo.Products     p ON t.ProductID  = p.ProductID
INNER JOIN dbo.Stores       s ON t.StoreID    = s.StoreID
ORDER BY   t.Date DESC;
GO


-- ============================================================
--  SECTION B — SALES PERFORMANCE INSIGHTS
--  To understand how much money the business is making
-- ============================================================

-- B1. Overall Business Summary
-- Key financial metrics at a glance
SELECT
    COUNT(*)                        AS TotalTransactions,
    COUNT(DISTINCT CustomerID)      AS UniqueCustomers,
    COUNT(DISTINCT ProductID)       AS UniqueProducts,
    SUM(TotalAmount)                AS TotalRevenue,
    AVG(TotalAmount)                AS AvgTransactionValue,
    MAX(TotalAmount)                AS HighestTransaction,
    MIN(TotalAmount)                AS LowestTransaction,
    SUM(Quantity)                   AS TotalItemsSold
FROM dbo.Transactions;
GO

-- B2. Monthly Revenue Trend
-- Shows how revenue changes month by month 
SELECT
    FORMAT(Date, 'yyyy-MM')         AS YearMonth,
    COUNT(*)                        AS NumTransactions,
    SUM(Quantity)                   AS TotalItemsSold,
    ROUND(SUM(TotalAmount), 2)      AS MonthlyRevenue,
    ROUND(AVG(TotalAmount), 2)      AS AvgTransactionValue
FROM   dbo.Transactions
GROUP  BY FORMAT(Date, 'yyyy-MM')
ORDER  BY YearMonth;
GO

-- B3. Yearly Revenue Comparison
-- Compare 2023 vs 2024 vs 2025 performance
SELECT
    YEAR(Date)                      AS Year,
    COUNT(*)                        AS TotalTransactions,
    ROUND(SUM(TotalAmount), 2)      AS TotalRevenue,
    ROUND(AVG(TotalAmount), 2)      AS AvgTransactionValue,
    SUM(Quantity)                   AS TotalItemsSold
FROM   dbo.Transactions
GROUP  BY YEAR(Date)
ORDER  BY Year;
GO

-- B4. Revenue by Day of Week
-- Which day of the week generates the most sales?
SELECT
    DATENAME(WEEKDAY, Date)         AS DayOfWeek,
    COUNT(*)                        AS NumTransactions,
    ROUND(SUM(TotalAmount), 2)      AS TotalRevenue,
    ROUND(AVG(TotalAmount), 2)      AS AvgRevenue
FROM   dbo.Transactions
GROUP  BY DATENAME(WEEKDAY, Date),
          DATEPART(WEEKDAY, Date)
ORDER  BY DATEPART(WEEKDAY, Date);
GO

-- B5. Revenue by Quarter
-- Identify which quarter performs best
SELECT
    YEAR(Date)                      AS Year,
    DATEPART(QUARTER, Date)         AS Quarter,
    COUNT(*)                        AS NumTransactions,
    ROUND(SUM(TotalAmount), 2)      AS QuarterlyRevenue
FROM   dbo.Transactions
GROUP  BY YEAR(Date), DATEPART(QUARTER, Date)
ORDER  BY Year, Quarter;
GO


-- ============================================================
--  SECTION C — PRODUCT INSIGHTS
--  To find best/worst performing products and categories
-- ============================================================

-- C1. Revenue by Product Category
-- Which category (Electronics / Fashion / Groceries) earns the most?
SELECT
    p.Category,
    COUNT(t.TransactionID)          AS NumTransactions,
    SUM(t.Quantity)                 AS TotalUnitsSold,
    ROUND(SUM(t.TotalAmount), 2)    AS TotalRevenue,
    ROUND(AVG(t.TotalAmount), 2)    AS AvgTransactionValue,
    ROUND(AVG(p.ProfitMargin), 2)   AS AvgProfitMargin
FROM       dbo.Transactions t
INNER JOIN dbo.Products     p ON t.ProductID = p.ProductID
GROUP BY   p.Category
ORDER BY   TotalRevenue DESC;
GO

-- C2. Revenue by Sub-Category
-- Drill down into finer product groupings
SELECT
    p.Category,
    p.SubCategory,
    COUNT(t.TransactionID)          AS NumTransactions,
    SUM(t.Quantity)                 AS TotalUnitsSold,
    ROUND(SUM(t.TotalAmount), 2)    AS TotalRevenue
FROM       dbo.Transactions t
INNER JOIN dbo.Products     p ON t.ProductID = p.ProductID
GROUP BY   p.Category, p.SubCategory
ORDER BY   TotalRevenue DESC;
GO

-- C3. Top 10 Best-Selling Products by Revenue
SELECT TOP 10
    p.ProductID,
    p.ProductName,
    p.Category,
    p.UnitPrice,
    p.ProfitMargin,
    COUNT(t.TransactionID)          AS TimesSold,
    SUM(t.Quantity)                 AS TotalUnitsSold,
    ROUND(SUM(t.TotalAmount), 2)    AS TotalRevenue
FROM       dbo.Transactions t
INNER JOIN dbo.Products     p ON t.ProductID = p.ProductID
GROUP BY   p.ProductID, p.ProductName, p.Category, p.UnitPrice, p.ProfitMargin
ORDER BY   TotalRevenue DESC;
GO

-- C4. Bottom 10 Worst-Selling Products by Revenue
-- Identifies products that may need promotion or discontinuation
SELECT TOP 10
    p.ProductID,
    p.ProductName,
    p.Category,
    COUNT(t.TransactionID)          AS TimesSold,
    SUM(t.Quantity)                 AS TotalUnitsSold,
    ROUND(SUM(t.TotalAmount), 2)    AS TotalRevenue
FROM       dbo.Transactions t
INNER JOIN dbo.Products     p ON t.ProductID = p.ProductID
GROUP BY   p.ProductID, p.ProductName, p.Category
ORDER BY   TotalRevenue ASC;
GO

-- C5. Most Profitable Products (by Profit Margin %)
SELECT
    p.ProductID,
    p.ProductName,
    p.Category,
    p.UnitPrice,
    p.CostPrice,
    p.ProfitMargin,
    ROUND(SUM(t.TotalAmount), 2)    AS TotalRevenue,
    ROUND(SUM(t.TotalAmount) * (p.ProfitMargin/100), 2) AS EstimatedProfit
FROM       dbo.Transactions t
INNER JOIN dbo.Products     p ON t.ProductID = p.ProductID
GROUP BY   p.ProductID, p.ProductName, p.Category,
           p.UnitPrice, p.CostPrice, p.ProfitMargin
ORDER BY   EstimatedProfit DESC;
GO

-- C6. Category Revenue Share (percentage of total)
SELECT
    p.Category,
    ROUND(SUM(t.TotalAmount), 2)    AS CategoryRevenue,
    ROUND(
        SUM(t.TotalAmount) * 100.0
        / SUM(SUM(t.TotalAmount)) OVER(), 2
    )                               AS RevenueSharePct
FROM       dbo.Transactions t
INNER JOIN dbo.Products     p ON t.ProductID = p.ProductID
GROUP BY   p.Category
ORDER BY   CategoryRevenue DESC;
GO


-- ============================================================
--  SECTION D — CUSTOMER INSIGHTS
--  To understand who your customers are and how they buy
-- ============================================================

-- D1. Customer Demographics Summary
SELECT
    Gender,
    COUNT(*)                        AS TotalCustomers,
    ROUND(AVG(Age), 1)              AS AvgAge,
    MIN(Age)                        AS YoungestAge,
    MAX(Age)                        AS OldestAge
FROM   dbo.Customers
GROUP  BY Gender;
GO

-- D2. Customer Age Group Analysis
-- Segment customers into age brackets
SELECT
    CASE
        WHEN Age BETWEEN 16 AND 25 THEN '16–25 (Gen Z)'
        WHEN Age BETWEEN 26 AND 35 THEN '26–35 (Millennial)'
        WHEN Age BETWEEN 36 AND 50 THEN '36–50 (Gen X)'
        WHEN Age BETWEEN 51 AND 65 THEN '51–65 (Boomer)'
        ELSE                             '65+ (Senior)'
    END                             AS AgeGroup,
    COUNT(*)                        AS NumCustomers
FROM   dbo.Customers
GROUP  BY
    CASE
        WHEN Age BETWEEN 16 AND 25 THEN '16–25 (Gen Z)'
        WHEN Age BETWEEN 26 AND 35 THEN '26–35 (Millennial)'
        WHEN Age BETWEEN 36 AND 50 THEN '36–50 (Gen X)'
        WHEN Age BETWEEN 51 AND 65 THEN '51–65 (Boomer)'
        ELSE                             '65+ (Senior)'
    END
ORDER  BY MIN(Age);
GO

-- D3. Top 10 Highest Spending Customers
SELECT TOP 10
    c.CustomerID,
    c.FullName,
    c.Gender,
    c.City,
    c.Age,
    COUNT(t.TransactionID)          AS TotalOrders,
    SUM(t.Quantity)                 AS TotalItemsBought,
    ROUND(SUM(t.TotalAmount), 2)    AS TotalSpent,
    ROUND(AVG(t.TotalAmount), 2)    AS AvgOrderValue
FROM       dbo.Transactions t
INNER JOIN dbo.Customers    c ON t.CustomerID = c.CustomerID
GROUP BY   c.CustomerID, c.FullName, c.Gender, c.City, c.Age
ORDER BY   TotalSpent DESC;
GO

-- D4. Customer Purchase Frequency Segments
-- Classify customers as High / Medium / Low frequency buyers
SELECT
    FrequencySegment,
    COUNT(*)                        AS NumCustomers,
    ROUND(AVG(TotalSpent), 2)       AS AvgSpend
FROM (
    SELECT
        c.CustomerID,
        c.FullName,
        COUNT(t.TransactionID)      AS OrderCount,
        SUM(t.TotalAmount)          AS TotalSpent,
        CASE
            WHEN COUNT(t.TransactionID) >= 40 THEN 'High Frequency (40+)'
            WHEN COUNT(t.TransactionID) >= 20 THEN 'Medium Frequency (20–39)'
            ELSE                                    'Low Frequency (<20)'
        END                         AS FrequencySegment
    FROM       dbo.Transactions t
    INNER JOIN dbo.Customers    c ON t.CustomerID = c.CustomerID
    GROUP BY   c.CustomerID, c.FullName
) AS Segments
GROUP BY FrequencySegment
ORDER BY MIN(
    CASE FrequencySegment
        WHEN 'High Frequency (40+)'      THEN 1
        WHEN 'Medium Frequency (20–39)'  THEN 2
        ELSE                                  3
    END
);
GO

-- D5. Revenue by Customer Gender
SELECT
    c.Gender,
    COUNT(DISTINCT t.CustomerID)    AS UniqueCustomers,
    COUNT(t.TransactionID)          AS TotalOrders,
    ROUND(SUM(t.TotalAmount), 2)    AS TotalRevenue,
    ROUND(AVG(t.TotalAmount), 2)    AS AvgOrderValue
FROM       dbo.Transactions t
INNER JOIN dbo.Customers    c ON t.CustomerID = c.CustomerID
GROUP BY   c.Gender;
GO

-- D6. New Customers Joined per Month
SELECT
    CAST(YEAR(JoinDate) AS VARCHAR(4)) + '-' + 
    RIGHT('0' + CAST(MONTH(JoinDate) AS VARCHAR(2)), 2) AS JoinMonth,
    COUNT(*)                        AS NewCustomers,
    SUM(COUNT(*)) OVER (
        ORDER BY YEAR(JoinDate), MONTH(JoinDate)
    )                               AS CumulativeCustomers
FROM   dbo.Customers
GROUP  BY YEAR(JoinDate), MONTH(JoinDate)
ORDER  BY YEAR(JoinDate), MONTH(JoinDate);
GO

-- D7. Customers with Only 1 Purchase (at-risk of churning)
SELECT
    c.CustomerID,
    c.FullName,
    c.City,
    c.Gender,
    COUNT(t.TransactionID)          AS TotalOrders,
    ROUND(SUM(t.TotalAmount), 2)    AS TotalSpent
FROM       dbo.Transactions t
INNER JOIN dbo.Customers    c ON t.CustomerID = c.CustomerID
GROUP BY   c.CustomerID, c.FullName, c.City, c.Gender
HAVING     COUNT(t.TransactionID) = 1
ORDER BY   TotalSpent DESC;
GO


-- ============================================================
--  SECTION E — STORE PERFORMANCE INSIGHTS
--  To compare stores and regions
-- ============================================================

-- E1. Revenue by Store
SELECT
    s.StoreID,
    s.StoreName,
    s.City,
    s.Region,
    COUNT(t.TransactionID)          AS NumTransactions,
    ROUND(SUM(t.TotalAmount), 2)    AS TotalRevenue,
    ROUND(AVG(t.TotalAmount), 2)    AS AvgTransactionValue,
    SUM(t.Quantity)                 AS TotalItemsSold
FROM       dbo.Transactions t
INNER JOIN dbo.Stores       s ON t.StoreID = s.StoreID
GROUP BY   s.StoreID, s.StoreName, s.City, s.Region
ORDER BY   TotalRevenue DESC;
GO

-- E2. Revenue by Region
SELECT
    s.Region,
    COUNT(DISTINCT s.StoreID)       AS NumStores,
    COUNT(t.TransactionID)          AS NumTransactions,
    ROUND(SUM(t.TotalAmount), 2)    AS TotalRevenue,
    ROUND(AVG(t.TotalAmount), 2)    AS AvgTransactionValue,
    ROUND(
        SUM(t.TotalAmount) * 100.0
        / SUM(SUM(t.TotalAmount)) OVER(), 2
    )                               AS RevenueSharePct
FROM       dbo.Transactions t
INNER JOIN dbo.Stores       s ON t.StoreID = s.StoreID
GROUP BY   s.Region
ORDER BY   TotalRevenue DESC;
GO

-- E3. Best-Selling Product Category per Store
-- Which category is most popular at each store location?
SELECT
    s.StoreName,
    s.Region,
    p.Category,
    COUNT(t.TransactionID)          AS NumTransactions,
    ROUND(SUM(t.TotalAmount), 2)    AS CategoryRevenue
FROM       dbo.Transactions t
INNER JOIN dbo.Stores       s ON t.StoreID  = s.StoreID
INNER JOIN dbo.Products     p ON t.ProductID = p.ProductID
GROUP BY   s.StoreName, s.Region, p.Category
ORDER BY   s.StoreName, CategoryRevenue DESC;
GO

-- E4. Monthly Revenue by Store (performance over time)
SELECT
    FORMAT(t.Date, 'yyyy-MM')       AS YearMonth,
    s.StoreName,
    ROUND(SUM(t.TotalAmount), 2)    AS MonthlyRevenue
FROM       dbo.Transactions t
INNER JOIN dbo.Stores       s ON t.StoreID = s.StoreID
GROUP BY   FORMAT(t.Date, 'yyyy-MM'), s.StoreName
ORDER BY   YearMonth, MonthlyRevenue DESC;
GO


-- ============================================================
--  SECTION F — PAYMENT & DISCOUNT INSIGHTS
--  To understand how customers pay and discount impact
-- ============================================================

-- F1. Revenue by Payment Method
SELECT
    PaymentMethod,
    COUNT(*)                        AS NumTransactions,
    ROUND(SUM(TotalAmount), 2)      AS TotalRevenue,
    ROUND(AVG(TotalAmount), 2)      AS AvgTransactionValue,
    ROUND(COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER(), 2)  AS UsagePct
FROM   dbo.Transactions
GROUP  BY PaymentMethod
ORDER  BY TotalRevenue DESC;
GO

-- F2. Discount Impact Analysis
-- Does a higher discount lead to higher quantities purchased?
SELECT
    CASE
        WHEN Discount = 0.00 THEN 'No Discount (0%)'
        WHEN Discount = 0.05 THEN '5% Discount'
        WHEN Discount = 0.10 THEN '10% Discount'
        WHEN Discount = 0.15 THEN '15% Discount'
        ELSE                       'Other'
    END                             AS DiscountTier,
    COUNT(*)                        AS NumTransactions,
    ROUND(AVG(Quantity), 2)         AS AvgQuantity,
    ROUND(AVG(TotalAmount), 2)      AS AvgTransactionValue,
    ROUND(SUM(TotalAmount), 2)      AS TotalRevenue
FROM   dbo.Transactions
GROUP  BY
    CASE
        WHEN Discount = 0.00 THEN 'No Discount (0%)'
        WHEN Discount = 0.05 THEN '5% Discount'
        WHEN Discount = 0.10 THEN '10% Discount'
        WHEN Discount = 0.15 THEN '15% Discount'
        ELSE                       'Other'
    END
ORDER  BY MIN(Discount);
GO

-- F3. Payment Method Preference by Gender
SELECT
    c.Gender,
    t.PaymentMethod,
    COUNT(*)                        AS NumTransactions,
    ROUND(SUM(t.TotalAmount), 2)    AS TotalRevenue
FROM       dbo.Transactions t
INNER JOIN dbo.Customers    c ON t.CustomerID = c.CustomerID
GROUP BY   c.Gender, t.PaymentMethod
ORDER BY   c.Gender, TotalRevenue DESC;
GO

-- F4. Payment Method Preference by Region
SELECT
    s.Region,
    t.PaymentMethod,
    COUNT(*)                        AS NumTransactions
FROM       dbo.Transactions t
INNER JOIN dbo.Stores       s ON t.StoreID = s.StoreID
GROUP BY   s.Region, t.PaymentMethod
ORDER BY   s.Region, NumTransactions DESC;
GO


-- ============================================================
--  SECTION G — TREND & PATTERN ANALYSIS
--  To identify business patterns to support decisions
-- ============================================================

-- G1. Running Total Revenue (cumulative growth over time)
SELECT
    CAST(YEAR(Date) AS VARCHAR(4)) + '-' +
    RIGHT('0' + CAST(MONTH(Date) AS VARCHAR(2)), 2) AS YearMonth,
    ROUND(SUM(TotalAmount), 2)      AS MonthlyRevenue,
    ROUND(
        SUM(SUM(TotalAmount)) OVER (
            ORDER BY YEAR(Date), MONTH(Date)
        ), 2
    )                               AS CumulativeRevenue
FROM   dbo.Transactions
GROUP  BY YEAR(Date), MONTH(Date)
ORDER  BY YEAR(Date), MONTH(Date);
GO

-- G2. Month-over-Month Revenue Growth Rate
-- Calculates % change in revenue from one month to the next
WITH MonthlyRevenue AS (
    SELECT
        FORMAT(Date, 'yyyy-MM')     AS YearMonth,
        ROUND(SUM(TotalAmount), 2)  AS Revenue
    FROM   dbo.Transactions
    GROUP  BY FORMAT(Date, 'yyyy-MM')
)
SELECT
    YearMonth,
    Revenue,
    LAG(Revenue) OVER (ORDER BY YearMonth) AS PrevMonthRevenue,
    ROUND(
        (Revenue - LAG(Revenue) OVER (ORDER BY YearMonth))
        / NULLIF(LAG(Revenue) OVER (ORDER BY YearMonth), 0) * 100
    , 2)                            AS GrowthRatePct
FROM MonthlyRevenue
ORDER BY YearMonth;
GO

-- G3. Best Month for Each Product Category
-- Which month did each category perform best?
WITH CategoryMonthly AS (
    SELECT
        p.Category,
        FORMAT(t.Date, 'yyyy-MM')   AS YearMonth,
        ROUND(SUM(t.TotalAmount), 2) AS Revenue,
        RANK() OVER (
            PARTITION BY p.Category
            ORDER BY SUM(t.TotalAmount) DESC
        )                           AS RevenueRank
    FROM       dbo.Transactions t
    INNER JOIN dbo.Products     p ON t.ProductID = p.ProductID
    GROUP BY   p.Category, FORMAT(t.Date, 'yyyy-MM')
)
SELECT Category, YearMonth AS BestMonth, Revenue
FROM   CategoryMonthly
WHERE  RevenueRank = 1
ORDER  BY Revenue DESC;
GO

-- G4. Quantity Sold Trend by Category per Month
SELECT
    FORMAT(t.Date, 'yyyy-MM')       AS YearMonth,
    p.Category,
    SUM(t.Quantity)                 AS TotalQuantitySold
FROM       dbo.Transactions t
INNER JOIN dbo.Products     p ON t.ProductID = p.ProductID
GROUP BY   FORMAT(t.Date, 'yyyy-MM'), p.Category
ORDER BY   YearMonth, p.Category;
GO

-- G5. Repeat Purchase Pattern
-- How many customers came back to buy more than once?
SELECT
    OrderCount,
    COUNT(*)                        AS NumCustomers
FROM (
    SELECT
        CustomerID,
        COUNT(TransactionID)        AS OrderCount
    FROM   dbo.Transactions
    GROUP  BY CustomerID
) AS CustomerOrders
GROUP  BY OrderCount
ORDER  BY OrderCount;
GO


-- ============================================================
--  SECTION H — SUMMARY VIEWS FOR REPORTING
--  To save useful queries as reusable SQL Views
-- ============================================================

-- H1. Create View: Full Transaction Details
-- A reusable view that joins all 4 tables
CREATE OR ALTER VIEW vw_TransactionDetails AS
SELECT
    t.TransactionID,
    t.Date,
    YEAR(t.Date)                    AS Year,
    MONTH(t.Date)                   AS Month,
    FORMAT(t.Date, 'yyyy-MM')       AS YearMonth,
    DATENAME(WEEKDAY, t.Date)       AS DayOfWeek,
    c.CustomerID,
    c.FullName                      AS CustomerName,
    c.Gender,
    c.Age,
    c.City                          AS CustomerCity,
    p.ProductID,
    p.ProductName,
    p.Category,
    p.SubCategory,
    p.UnitPrice,
    p.CostPrice,
    p.ProfitMargin,
    s.StoreID,
    s.StoreName,
    s.City                          AS StoreCity,
    s.Region,
    t.Quantity,
    t.Discount,
    t.PaymentMethod,
    t.TotalAmount,
    ROUND(t.TotalAmount * (p.ProfitMargin/100), 2) AS EstimatedProfit
FROM       dbo.Transactions t
INNER JOIN dbo.Customers    c ON t.CustomerID = c.CustomerID
INNER JOIN dbo.Products     p ON t.ProductID  = p.ProductID
INNER JOIN dbo.Stores       s ON t.StoreID    = s.StoreID;
GO

-- H2. Create View: Monthly Sales Summary
CREATE OR ALTER VIEW vw_MonthlySummary AS
SELECT
    FORMAT(Date, 'yyyy-MM')         AS YearMonth,
    YEAR(Date)                      AS Year,
    MONTH(Date)                     AS Month,
    COUNT(TransactionID)            AS NumTransactions,
    COUNT(DISTINCT CustomerID)      AS UniqueCustomers,
    SUM(Quantity)                   AS TotalItemsSold,
    ROUND(SUM(TotalAmount), 2)      AS TotalRevenue,
    ROUND(AVG(TotalAmount), 2)      AS AvgTransactionValue
FROM   dbo.Transactions
GROUP  BY FORMAT(Date, 'yyyy-MM'), YEAR(Date), MONTH(Date);
GO

-- H3. Create View: Customer Summary (RFM base)
-- RFM = Recency, Frequency, Monetary — a standard marketing segmentation
CREATE OR ALTER VIEW vw_CustomerSummary AS
SELECT
    c.CustomerID,
    c.FullName,
    c.Gender,
    c.Age,
    c.City,
    c.JoinDate,
    COUNT(t.TransactionID)          AS TotalOrders,
    SUM(t.Quantity)                 AS TotalItemsBought,
    ROUND(SUM(t.TotalAmount), 2)    AS TotalSpent,
    ROUND(AVG(t.TotalAmount), 2)    AS AvgOrderValue,
    MIN(t.Date)                     AS FirstPurchase,
    MAX(t.Date)                     AS LastPurchase,
    DATEDIFF(DAY, MAX(t.Date), GETDATE()) AS DaysSinceLastPurchase
FROM       dbo.Customers    c
INNER JOIN dbo.Transactions t ON c.CustomerID = t.CustomerID
GROUP BY   c.CustomerID, c.FullName, c.Gender, c.Age,
           c.City, c.JoinDate;
GO

-- Test all views
SELECT TOP 5 * FROM vw_TransactionDetails;
SELECT TOP 5 * FROM vw_MonthlySummary;
SELECT TOP 5 * FROM vw_CustomerSummary ORDER BY TotalSpent DESC;
GO


-- ============================================================
--  SECTION I — BUSINESS DECISION SUPPORT QUERIES
--  Direct answers to key business questions
-- ============================================================

-- I1. DECISION: Which products should we promote?
--      Low sales volume but high profit margin
SELECT
    p.ProductID,
    p.ProductName,
    p.Category,
    p.ProfitMargin,
    COUNT(t.TransactionID)          AS TimesSold,
    ROUND(SUM(t.TotalAmount), 2)    AS TotalRevenue
FROM       dbo.Transactions t
INNER JOIN dbo.Products     p ON t.ProductID = p.ProductID
GROUP BY   p.ProductID, p.ProductName, p.Category, p.ProfitMargin
HAVING     COUNT(t.TransactionID) < 80          -- Low sales
       AND p.ProfitMargin > 40                  -- But high margin
ORDER BY   p.ProfitMargin DESC;
GO


-- I2. DECISION: Which store needs attention?
--     ? Stores below average revenue
SELECT
    s.StoreName,
    s.Region,
    ROUND(SUM(t.TotalAmount), 2)    AS StoreRevenue,
    ROUND(AVG(SUM(t.TotalAmount)) OVER (), 2) AS AvgStoreRevenue,
    CASE
        WHEN SUM(t.TotalAmount) < AVG(SUM(t.TotalAmount)) OVER()
        THEN 'Below Average'
        ELSE 'Above Average'
    END                             AS PerformanceFlag
FROM       dbo.Transactions t
INNER JOIN dbo.Stores       s ON t.StoreID = s.StoreID
GROUP BY   s.StoreName, s.Region
ORDER BY   StoreRevenue DESC;
GO

-- I3. DECISION: What is the best-performing month historically?
SELECT TOP 3
    FORMAT(Date, 'yyyy-MM')         AS Month,
    ROUND(SUM(TotalAmount), 2)      AS Revenue,
    COUNT(*)                        AS NumTransactions
FROM   dbo.Transactions
GROUP  BY FORMAT(Date, 'yyyy-MM')
ORDER  BY Revenue DESC;
GO

-- I4. DECISION: Which product (category + region combination is strongest?
SELECT
    s.Region,
    p.Category,
    COUNT(t.TransactionID)          AS NumTransactions,
    ROUND(SUM(t.TotalAmount), 2)    AS TotalRevenue
FROM       dbo.Transactions t
INNER JOIN dbo.Stores       s ON t.StoreID  = s.StoreID
INNER JOIN dbo.Products     p ON t.ProductID = p.ProductID
GROUP BY   s.Region, p.Category
ORDER BY   TotalRevenue DESC;
GO

PRINT 'All queries executed successfully!';
PRINT 'Views created: vw_TransactionDetails, vw_MonthlySummary, vw_CustomerSummary';
GO