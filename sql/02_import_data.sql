
USE RetailSalesDatabase;
GO

-- ============================================================
-- STEP 1 — Import Stores
-- ============================================================
BULK INSERT dbo.Stores
FROM 'F:\physical science\4th year\Internship\Task 12\retail-sales-business-database\data\cleaned_data\stores_clean.csv'
WITH (
    FIRSTROW        = 2,            -- Skip the header row
    FIELDTERMINATOR = ',',          -- Columns are separated by comma
    ROWTERMINATOR   = '\n',         -- Each row ends with newline
    TABLOCK                         -- Locks table for faster import
);
GO

-- Verify Stores loaded correctly
SELECT * FROM dbo.Stores;
GO

-- ============================================================
-- STEP 2 — Import Products
-- ============================================================
BULK INSERT dbo.Products
FROM 'F:\physical science\4th year\Internship\Task 12\retail-sales-business-database\data\cleaned_data\products_clean.csv'
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '\n',
    TABLOCK
);
GO

-- Verify Products loaded correctly
SELECT * FROM dbo.Products;
GO

-- ============================================================
-- STEP 3 — Import Customers
-- ============================================================

BULK INSERT dbo.Customers
FROM 'F:\physical science\4th year\Internship\Task 12\retail-sales-business-database\data\cleaned_data\customers_clean.csv'
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '\n',
    TABLOCK
);
GO

-- Verify Customers loaded correctly
SELECT TOP 5 * FROM dbo.Customers;
GO

-- ============================================================
-- STEP 4 — Import Transactions
-- ============================================================

BULK INSERT dbo.Transactions
FROM 'F:\physical science\4th year\Internship\Task 12\retail-sales-business-database\data\cleaned_data\transactions_clean.csv'
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '\n',
    TABLOCK
);
GO

-- Verify Transactions loaded correctly
SELECT TOP 5 * FROM dbo.Transactions;
GO

-- ============================================================
-- STEP 5 — Final Row Count Check (confirm all data loaded)
-- ============================================================

SELECT 'Customers'    AS TableName, COUNT(*) AS TotalRows FROM dbo.Customers
UNION ALL
SELECT 'Products'     AS TableName, COUNT(*) AS TotalRows FROM dbo.Products
UNION ALL
SELECT 'Stores'       AS TableName, COUNT(*) AS TotalRows FROM dbo.Stores
UNION ALL
SELECT 'Transactions' AS TableName, COUNT(*) AS TotalRows FROM dbo.Transactions;
GO


-- ============================================================
-- STEP 6 — Referential Integrity Check
-- ============================================================

-- Check: any CustomerID in Transactions not found in Customers?
SELECT t.TransactionID, t.CustomerID
FROM   dbo.Transactions t
WHERE  t.CustomerID NOT IN (SELECT CustomerID FROM dbo.Customers);

-- Check: any ProductID in Transactions not found in Products?
SELECT t.TransactionID, t.ProductID
FROM   dbo.Transactions t
WHERE  t.ProductID NOT IN (SELECT ProductID FROM dbo.Products);

-- Check: any StoreID in Transactions not found in Stores?
SELECT t.TransactionID, t.StoreID
FROM   dbo.Transactions t
WHERE  t.StoreID NOT IN (SELECT StoreID FROM dbo.Stores);

-- All 3 queries should return 0 rows
GO

PRINT 'Data import complete! All tables loaded successfully.';
GO