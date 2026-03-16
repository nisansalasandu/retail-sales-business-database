
USE RetailSalesDataBase;
GO


-- ============================================================
-- PART 1 — EXECUTIVE SUMMARY TABLE                           
-- A single table with all top-level KPIs for reporting       
-- ============================================================

-- Full Business KPI Dashboard (one-glance summary)
-- Shows the most important numbers the business cares about
SELECT
    -- Volume metrics
    COUNT(*)                                        AS TotalTransactions,
    COUNT(DISTINCT t.CustomerID)                    AS ActiveCustomers,
    COUNT(DISTINCT t.ProductID)                     AS ProductsSold,
    COUNT(DISTINCT t.StoreID)                       AS StoresActive,
    SUM(t.Quantity)                                 AS TotalItemsSold,

    -- Revenue metrics
    ROUND(SUM(t.TotalAmount), 2)                    AS TotalRevenue,
    ROUND(AVG(t.TotalAmount), 2)                    AS AvgTransactionValue,
    ROUND(MAX(t.TotalAmount), 2)                    AS HighestSale,
    ROUND(MIN(t.TotalAmount), 2)                    AS LowestSale,

    -- Profitability
    ROUND(AVG(p.ProfitMargin), 2)                   AS AvgProfitMargin_Pct,
    ROUND(SUM(t.TotalAmount * p.ProfitMargin/100), 2) AS EstimatedTotalProfit,

    -- Time span
    MIN(t.Date)                                     AS EarliestTransaction,
    MAX(t.Date)                                     AS LatestTransaction,
    DATEDIFF(MONTH, MIN(t.Date), MAX(t.Date)) + 1   AS MonthsCovered

FROM       dbo.Transactions t
INNER JOIN dbo.Products     p ON t.ProductID = p.ProductID;
GO


-- ============================================================
-- PART 2 — REVENUE TREND SUMMARIES                           
-- Month-by-month and year-by-year breakdown                  
-- ============================================================

-- Monthly Revenue Summary with Growth Flag
-- Labels each month as GROWTH, DECLINE, or STABLE vs previous month
WITH Monthly AS (
    SELECT
        YEAR(Date)                                          AS Yr,
        MONTH(Date)                                         AS Mo,
        CAST(YEAR(Date) AS VARCHAR(4)) + '-' +
            RIGHT('0' + CAST(MONTH(Date) AS VARCHAR(2)),2)  AS YearMonth,
        ROUND(SUM(TotalAmount), 2)                          AS Revenue,
        COUNT(*)                                            AS NumTransactions,
        SUM(Quantity)                                       AS ItemsSold
    FROM   dbo.Transactions
    GROUP  BY YEAR(Date), MONTH(Date)
)
SELECT
    YearMonth,
    Revenue,
    NumTransactions,
    ItemsSold,
    LAG(Revenue) OVER (ORDER BY Yr, Mo)             AS PrevRevenue,
    ROUND(
        (Revenue - LAG(Revenue) OVER (ORDER BY Yr, Mo))
        / NULLIF(LAG(Revenue) OVER (ORDER BY Yr, Mo), 0) * 100
    , 2)                                            AS GrowthPct,
    CASE
        WHEN Revenue > LAG(Revenue) OVER (ORDER BY Yr, Mo) * 1.05  THEN 'GROWTH  ▲'
        WHEN Revenue < LAG(Revenue) OVER (ORDER BY Yr, Mo) * 0.95  THEN 'DECLINE ▼'
        ELSE                                                              'STABLE  ─'
    END                                             AS Trend
FROM Monthly
ORDER BY Yr, Mo;
GO

-- Yearly Revenue Summary with Year-over-Year % Change
WITH Yearly AS (
    SELECT
        YEAR(Date)                      AS Year,
        ROUND(SUM(TotalAmount), 2)      AS Revenue,
        COUNT(*)                        AS Transactions,
        SUM(Quantity)                   AS ItemsSold,
        COUNT(DISTINCT CustomerID)      AS UniqueCustomers
    FROM   dbo.Transactions
    GROUP  BY YEAR(Date)
)
SELECT
    Year,
    Revenue,
    Transactions,
    ItemsSold,
    UniqueCustomers,
    LAG(Revenue) OVER (ORDER BY Year)   AS PrevYearRevenue,
    ROUND(
        (Revenue - LAG(Revenue) OVER (ORDER BY Year))
        / NULLIF(LAG(Revenue) OVER (ORDER BY Year), 0) * 100
    , 2)                                AS YoY_GrowthPct
FROM Yearly
ORDER BY Year;
GO

-- Seasonal Pattern — Average Revenue by Month Number
-- Reveals which months are consistently strong/weak

SELECT
    Mo                                                          AS MonthNumber,
    DATENAME(MONTH, DATEFROMPARTS(2000, Mo, 1))                 AS MonthName,
    COUNT(DISTINCT Yr)                                          AS YearsOfData,
    ROUND(AVG(MonthlyRev), 2)                                   AS AvgMonthlyRevenue,
    ROUND(MIN(MonthlyRev), 2)                                   AS MinRevenue,
    ROUND(MAX(MonthlyRev), 2)                                   AS MaxRevenue
FROM (
    SELECT
        YEAR(Date)                      AS Yr,
        MONTH(Date)                     AS Mo,
        SUM(TotalAmount)                AS MonthlyRev
    FROM   dbo.Transactions
    WHERE  NOT (YEAR(Date) = 2023 AND MONTH(Date) = 9)
       AND NOT (YEAR(Date) = 2025 AND MONTH(Date) = 9)
    GROUP  BY YEAR(Date), MONTH(Date)
) AS MonthlyData
GROUP  BY Mo
ORDER  BY Mo;
GO

-- Best and Worst 5 Months Overall
-- Top 5 performers
SELECT TOP 5
    FORMAT(Date, 'yyyy-MM')             AS Month,
    ROUND(SUM(TotalAmount), 2)          AS Revenue,
    COUNT(*)                            AS Transactions,
    'Top 5'                             AS Ranking
FROM   dbo.Transactions
GROUP  BY FORMAT(Date, 'yyyy-MM')
ORDER  BY Revenue DESC;
GO

-- Bottom 5 performers (excluding partial Sept 2025)
SELECT TOP 5
    FORMAT(Date, 'yyyy-MM')             AS Month,
    ROUND(SUM(TotalAmount), 2)          AS Revenue,
    COUNT(*)                            AS Transactions,
    'Bottom 5'                          AS Ranking
FROM   dbo.Transactions
WHERE  NOT (YEAR(Date) = 2025 AND MONTH(Date) = 9)  -- Exclude partial month
GROUP  BY FORMAT(Date, 'yyyy-MM')
ORDER  BY Revenue ASC;
GO


-- ============================================================
-- PART 3 — PRODUCT PERFORMANCE SUMMARY                       
-- ============================================================

-- Product Category Summary Card
-- Clean one-table summary per category
SELECT
    p.Category,
    COUNT(DISTINCT p.ProductID)             AS NumProducts,
    COUNT(t.TransactionID)                  AS NumTransactions,
    SUM(t.Quantity)                         AS TotalUnitsSold,
    ROUND(SUM(t.TotalAmount), 2)            AS TotalRevenue,
    ROUND(AVG(t.TotalAmount), 2)            AS AvgSaleValue,
    ROUND(AVG(p.ProfitMargin), 2)           AS AvgProfitMargin,
    ROUND(SUM(t.TotalAmount * p.ProfitMargin/100), 2) AS EstimatedProfit,
    ROUND(SUM(t.TotalAmount) * 100.0
        / SUM(SUM(t.TotalAmount)) OVER(), 2) AS RevenueShare_Pct
FROM       dbo.Transactions t
INNER JOIN dbo.Products     p ON t.ProductID = p.ProductID
GROUP BY   p.Category
ORDER BY   TotalRevenue DESC;
GO

-- Product Performance Tier Classification
-- Classifies every product as Star, Growing, Watch, or Declining
WITH ProductStats AS (
    SELECT
        p.ProductID,
        p.ProductName,
        p.Category,
        p.ProfitMargin,
        COUNT(t.TransactionID)          AS TimesSold,
        ROUND(SUM(t.TotalAmount), 2)    AS Revenue
    FROM       dbo.Transactions t
    INNER JOIN dbo.Products     p ON t.ProductID = p.ProductID
    GROUP BY   p.ProductID, p.ProductName, p.Category, p.ProfitMargin
),
Averages AS (
    SELECT
        AVG(CAST(TimesSold AS FLOAT))   AS AvgSales,
        AVG(Revenue)                    AS AvgRevenue
    FROM ProductStats
)
SELECT
    ps.ProductID,
    ps.ProductName,
    ps.Category,
    ps.TimesSold,
    ps.Revenue,
    ps.ProfitMargin,
    CASE
        WHEN ps.Revenue >= a.AvgRevenue AND ps.ProfitMargin >= 35
            THEN 'STAR — High Revenue + High Margin'
        WHEN ps.Revenue >= a.AvgRevenue AND ps.ProfitMargin < 35
            THEN 'VOLUME — High Revenue, Lower Margin'
        WHEN ps.Revenue < a.AvgRevenue AND ps.ProfitMargin >= 35
            THEN 'HIDDEN GEM — Low Revenue, High Margin'
        ELSE
            'REVIEW — Low Revenue + Low Margin'
    END                                 AS ProductTier
FROM       ProductStats ps
CROSS JOIN Averages     a
ORDER BY   ps.Revenue DESC;
GO

-- Subcategory Revenue Summary
SELECT
    p.Category,
    p.SubCategory,
    COUNT(DISTINCT p.ProductID)         AS NumProducts,
    COUNT(t.TransactionID)              AS Transactions,
    SUM(t.Quantity)                     AS UnitsSold,
    ROUND(SUM(t.TotalAmount), 2)        AS TotalRevenue,
    ROUND(AVG(p.ProfitMargin), 2)       AS AvgMargin,
    ROUND(
        SUM(t.TotalAmount) * 100.0
        / SUM(SUM(t.TotalAmount)) OVER (PARTITION BY p.Category)
    , 2)                                AS ShareWithinCategory_Pct
FROM       dbo.Transactions t
INNER JOIN dbo.Products     p ON t.ProductID = p.ProductID
GROUP BY   p.Category, p.SubCategory
ORDER BY   p.Category, TotalRevenue DESC;
GO


-- ============================================================
-- PART 4 — CUSTOMER BEHAVIOUR SUMMARY                        
-- ============================================================

-- RFM Scoring — Recency, Frequency, Monetary
-- Industry-standard customer segmentation model
-- R = days since last purchase (lower = better)
-- F = number of transactions (higher = better)
-- M = total amount spent (higher = better)
WITH RFM_Base AS (
    SELECT
        c.CustomerID,
        c.FullName,
        c.Gender,
        c.Age,
        c.City,
        DATEDIFF(DAY, MAX(t.Date), GETDATE())   AS Recency,
        COUNT(t.TransactionID)                  AS Frequency,
        ROUND(SUM(t.TotalAmount), 2)            AS Monetary
    FROM       dbo.Customers    c
    INNER JOIN dbo.Transactions t ON c.CustomerID = t.CustomerID
    GROUP BY   c.CustomerID, c.FullName, c.Gender, c.Age, c.City
),
RFM_Scored AS (
    SELECT *,
        -- R Score: 5=most recent, 1=least recent
        NTILE(5) OVER (ORDER BY Recency ASC)    AS R_Score,
        -- F Score: 5=most frequent, 1=least frequent
        NTILE(5) OVER (ORDER BY Frequency DESC) AS F_Score,
        -- M Score: 5=highest spend, 1=lowest spend
        NTILE(5) OVER (ORDER BY Monetary DESC)  AS M_Score
    FROM RFM_Base
)
SELECT
    CustomerID,
    FullName,
    Gender,
    Age,
    Recency,
    Frequency,
    Monetary,
    R_Score,
    F_Score,
    M_Score,
    (R_Score + F_Score + M_Score)               AS RFM_Total,
    CASE
        WHEN (R_Score + F_Score + M_Score) >= 13 THEN 'Champions'
        WHEN (R_Score + F_Score + M_Score) >= 10 THEN 'Loyal Customers'
        WHEN (R_Score + F_Score + M_Score) >= 7  THEN 'Potential Loyalists'
        WHEN (R_Score + F_Score + M_Score) >= 5  THEN 'At Risk'
        ELSE                                          'Lost Customers'
    END                                         AS CustomerSegment
FROM RFM_Scored
ORDER BY RFM_Total DESC;
GO

-- Customer Segment Summary (how many in each RFM segment)
WITH RFM_Base AS (
    SELECT
        c.CustomerID,
        DATEDIFF(DAY, MAX(t.Date), GETDATE())   AS Recency,
        COUNT(t.TransactionID)                  AS Frequency,
        ROUND(SUM(t.TotalAmount), 2)            AS Monetary
    FROM       dbo.Customers    c
    INNER JOIN dbo.Transactions t ON c.CustomerID = t.CustomerID
    GROUP BY   c.CustomerID
),
RFM_Scored AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY Recency ASC)    AS R_Score,
        NTILE(5) OVER (ORDER BY Frequency DESC) AS F_Score,
        NTILE(5) OVER (ORDER BY Monetary DESC)  AS M_Score
    FROM RFM_Base
)
SELECT
    CASE
        WHEN (R_Score + F_Score + M_Score) >= 13 THEN 'Champions'
        WHEN (R_Score + F_Score + M_Score) >= 10 THEN 'Loyal Customers'
        WHEN (R_Score + F_Score + M_Score) >= 7  THEN 'Potential Loyalists'
        WHEN (R_Score + F_Score + M_Score) >= 5  THEN 'At Risk'
        ELSE                                          'Lost Customers'
    END                                         AS CustomerSegment,
    COUNT(*)                                    AS NumCustomers,
    ROUND(AVG(Monetary), 2)                     AS AvgSpend,
    ROUND(AVG(CAST(Frequency AS FLOAT)), 1)     AS AvgOrders,
    ROUND(AVG(CAST(Recency AS FLOAT)), 0)       AS AvgDaysSincePurchase
FROM RFM_Scored
GROUP BY
    CASE
        WHEN (R_Score + F_Score + M_Score) >= 13 THEN 'Champions'
        WHEN (R_Score + F_Score + M_Score) >= 10 THEN 'Loyal Customers'
        WHEN (R_Score + F_Score + M_Score) >= 7  THEN 'Potential Loyalists'
        WHEN (R_Score + F_Score + M_Score) >= 5  THEN 'At Risk'
        ELSE                                          'Lost Customers'
    END
ORDER BY AvgSpend DESC;
GO

-- Customer Lifetime Value (CLV) Summary
-- Average spend per customer per month
WITH CustomerStats AS (
    SELECT
        c.CustomerID,
        c.FullName,
        c.Gender,
        c.Age,
        DATEDIFF(MONTH, MIN(t.Date), MAX(t.Date)) + 1   AS ActiveMonths,
        COUNT(t.TransactionID)                          AS TotalOrders,
        ROUND(SUM(t.TotalAmount), 2)                    AS TotalSpent
    FROM       dbo.Customers    c
    INNER JOIN dbo.Transactions t ON c.CustomerID = t.CustomerID
    GROUP BY   c.CustomerID, c.FullName, c.Gender, c.Age
)
SELECT
    CustomerID,
    FullName,
    Gender,
    Age,
    TotalOrders,
    TotalSpent,
    ActiveMonths,
    ROUND(TotalSpent / NULLIF(ActiveMonths, 0), 2)      AS MonthlySpendRate,
    ROUND(TotalSpent / NULLIF(ActiveMonths, 0) * 12, 2) AS ProjectedAnnualValue,
    CASE
        WHEN TotalSpent / NULLIF(ActiveMonths, 0) * 12 >= 80000 THEN 'High Value'
        WHEN TotalSpent / NULLIF(ActiveMonths, 0) * 12 >= 40000 THEN 'Medium Value'
        ELSE                                                          'Standard Value'
    END                                                 AS CLV_Tier
FROM CustomerStats
ORDER BY ProjectedAnnualValue DESC;
GO


-- ============================================================
--  PART 5 — STORE PERFORMANCE SUMMARY                         
-- ============================================================

-- Store KPI Scorecard
-- All key metrics for each store in one table
SELECT
    s.StoreID,
    s.StoreName,
    s.Region,
    COUNT(t.TransactionID)                          AS TotalTransactions,
    COUNT(DISTINCT t.CustomerID)                    AS UniqueCustomers,
    SUM(t.Quantity)                                 AS TotalItemsSold,
    ROUND(SUM(t.TotalAmount), 2)                    AS TotalRevenue,
    ROUND(AVG(t.TotalAmount), 2)                    AS AvgTransactionValue,
    ROUND(SUM(t.TotalAmount * p.ProfitMargin/100), 2) AS EstimatedProfit,
    ROUND(SUM(t.TotalAmount) * 100.0
        / SUM(SUM(t.TotalAmount)) OVER(), 2)        AS RevenueShare_Pct,
    CASE
        WHEN SUM(t.TotalAmount) >= AVG(SUM(t.TotalAmount)) OVER() * 1.05
            THEN 'Outperforming'
        WHEN SUM(t.TotalAmount) >= AVG(SUM(t.TotalAmount)) OVER() * 0.95
            THEN 'On Target'
        ELSE
            'Underperforming'
    END                                             AS PerformanceBand
FROM       dbo.Transactions t
INNER JOIN dbo.Stores       s ON t.StoreID  = s.StoreID
INNER JOIN dbo.Products     p ON t.ProductID = p.ProductID
GROUP BY   s.StoreID, s.StoreName, s.Region
ORDER BY   TotalRevenue DESC;
GO

-- Store Quarterly Performance Trend

SELECT
    s.StoreName,
    YEAR(t.Date)                            AS Year,
    DATEPART(QUARTER, t.Date)               AS Quarter,
    CONCAT('Q', DATEPART(QUARTER, t.Date),
           '-', YEAR(t.Date))               AS QuarterLabel,
    COUNT(t.TransactionID)                  AS Transactions,
    ROUND(SUM(t.TotalAmount), 2)            AS Revenue
FROM       dbo.Transactions t
INNER JOIN dbo.Stores       s ON t.StoreID = s.StoreID
GROUP BY   s.StoreName, YEAR(t.Date), DATEPART(QUARTER, t.Date)
ORDER BY   s.StoreName, Year, Quarter;
GO

-- Region vs Category Revenue Matrix
-- which category drives which region
SELECT
    s.Region,
    ROUND(SUM(CASE WHEN p.Category = 'Electronics' THEN t.TotalAmount ELSE 0 END), 2) AS Electronics_Revenue,
    ROUND(SUM(CASE WHEN p.Category = 'Fashion'     THEN t.TotalAmount ELSE 0 END), 2) AS Fashion_Revenue,
    ROUND(SUM(CASE WHEN p.Category = 'Groceries'   THEN t.TotalAmount ELSE 0 END), 2) AS Groceries_Revenue,
    ROUND(SUM(t.TotalAmount), 2)                                                       AS Total_Revenue
FROM       dbo.Transactions t
INNER JOIN dbo.Stores       s ON t.StoreID  = s.StoreID
INNER JOIN dbo.Products     p ON t.ProductID = p.ProductID
GROUP BY   s.Region
ORDER BY   Total_Revenue DESC;
GO


-- ============================================================
-- PART 6 — GAP ANALYSIS                                      
-- Find problems, risks, and missed opportunities             
-- ============================================================

-- Revenue Gap: Actual vs Target
-- If business targets 10% monthly growth from Sep 2023 
WITH Monthly AS (
    SELECT
        YEAR(Date)                                          AS Yr,
        MONTH(Date)                                         AS Mo,
        CAST(YEAR(Date) AS VARCHAR(4)) + '-' +
            RIGHT('0' + CAST(MONTH(Date) AS VARCHAR(2)),2)  AS YearMonth,
        ROUND(SUM(TotalAmount), 2)                          AS ActualRevenue,
        ROW_NUMBER() OVER (ORDER BY YEAR(Date), MONTH(Date)) - 1 AS MonthIndex
    FROM   dbo.Transactions
    GROUP  BY YEAR(Date), MONTH(Date)
)
SELECT
    YearMonth,
    ActualRevenue,
    ROUND(380992.34 * POWER(1.005, MonthIndex), 2)  AS TargetRevenue_05pct_Monthly,
    ROUND(ActualRevenue - (380992.34 * POWER(1.005, MonthIndex)), 2) AS RevenueGap,
    CASE
        WHEN ActualRevenue >= 380992.34 * POWER(1.005, MonthIndex)
        THEN 'Above Target'
        ELSE 'Below Target'
    END                                             AS TargetStatus
FROM Monthly
ORDER BY Yr, Mo;
GO

-- Underperforming Products (below average sales AND margin)
WITH ProductStats AS (
    SELECT
        p.ProductID,
        p.ProductName,
        p.Category,
        p.SubCategory,
        p.ProfitMargin,
        COUNT(t.TransactionID)          AS TimesSold,
        ROUND(SUM(t.TotalAmount), 2)    AS TotalRevenue,
        ROUND(AVG(t.TotalAmount), 2)    AS AvgSaleValue
    FROM       dbo.Transactions t
    INNER JOIN dbo.Products     p ON t.ProductID = p.ProductID
    GROUP BY   p.ProductID, p.ProductName, p.Category, p.SubCategory, p.ProfitMargin
),
Averages AS (
    SELECT
        AVG(CAST(TimesSold AS FLOAT))   AS AvgSales,
        AVG(TotalRevenue)               AS AvgRevenue,
        AVG(ProfitMargin)               AS AvgMargin
    FROM ProductStats
)
SELECT
    ps.ProductID,
    ps.ProductName,
    ps.Category,
    ps.SubCategory,
    ps.TimesSold,
    ps.TotalRevenue,
    ps.ProfitMargin,
    ROUND(a.AvgRevenue, 2)              AS AvgRevenueThreshold,
    ROUND(a.AvgMargin, 2)              AS AvgMarginThreshold,
    'Needs Attention — Discontinue or Promote' AS Recommendation
FROM       ProductStats ps
CROSS JOIN Averages     a
WHERE  ps.TotalRevenue < a.AvgRevenue
   AND ps.ProfitMargin < a.AvgMargin
ORDER BY   ps.TotalRevenue ASC;
GO



-- ============================================================
-- PART 7 — FINAL BUSINESS DECISION REPORT                    
-- Clear, actionable recommendations based on data            
-- ============================================================

-- Summary: Key Findings at
SELECT 'Total Revenue'          AS Metric, CAST(ROUND(SUM(TotalAmount),2) AS VARCHAR(30)) AS Value FROM dbo.Transactions UNION ALL
SELECT 'Total Transactions'     AS Metric, CAST(COUNT(*) AS VARCHAR(30)) FROM dbo.Transactions UNION ALL
SELECT 'Unique Customers'       AS Metric, CAST(COUNT(DISTINCT CustomerID) AS VARCHAR(30)) FROM dbo.Transactions UNION ALL
SELECT 'Avg Transaction Value'  AS Metric, CAST(ROUND(AVG(TotalAmount),2) AS VARCHAR(30)) FROM dbo.Transactions UNION ALL
SELECT 'Best Month Revenue'     AS Metric, CAST(ROUND(MAX(m), 2) AS VARCHAR(30)) FROM (SELECT SUM(TotalAmount) AS m FROM dbo.Transactions GROUP BY FORMAT(Date,'yyyy-MM')) x UNION ALL
SELECT 'Best Month'             AS Metric, FORMAT(Date,'yyyy-MM') FROM dbo.Transactions GROUP BY FORMAT(Date,'yyyy-MM') HAVING SUM(TotalAmount) = (SELECT MAX(s) FROM (SELECT SUM(TotalAmount) AS s FROM dbo.Transactions GROUP BY FORMAT(Date,'yyyy-MM')) t) UNION ALL
SELECT 'Top Category'           AS Metric, p.Category FROM dbo.Transactions t JOIN dbo.Products p ON t.ProductID=p.ProductID GROUP BY p.Category HAVING SUM(t.TotalAmount)=(SELECT MAX(s) FROM (SELECT SUM(t2.TotalAmount) s FROM dbo.Transactions t2 JOIN dbo.Products p2 ON t2.ProductID=p2.ProductID GROUP BY p2.Category) x) UNION ALL
SELECT 'Top Store'              AS Metric, s.StoreName FROM dbo.Transactions t JOIN dbo.Stores s ON t.StoreID=s.StoreID GROUP BY s.StoreName HAVING SUM(t.TotalAmount)=(SELECT MAX(sv) FROM (SELECT SUM(t2.TotalAmount) sv FROM dbo.Transactions t2 GROUP BY t2.StoreID) x);
GO


PRINT '======================================================';
PRINT ' All summaries and analysis done!';
PRINT '======================================================';
GO