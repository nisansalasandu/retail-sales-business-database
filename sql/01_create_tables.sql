USE RetailSalesDataBase;
GO

-- ?? Drop tables if they exist (clean re-run) ?????????????????
IF OBJECT_ID('dbo.Transactions', 'U') IS NOT NULL DROP TABLE dbo.Transactions;
IF OBJECT_ID('dbo.Customers',    'U') IS NOT NULL DROP TABLE dbo.Customers;
IF OBJECT_ID('dbo.Products',     'U') IS NOT NULL DROP TABLE dbo.Products;
IF OBJECT_ID('dbo.Stores',       'U') IS NOT NULL DROP TABLE dbo.Stores;
GO

-- ?? 1. Customers ?????????????????????????????????????????????
-- Stores customer demographic information
CREATE TABLE dbo.Customers (
    CustomerID   VARCHAR(10)   NOT NULL,   -- e.g. C001
    FirstName    VARCHAR(50)   NOT NULL,
    LastName     VARCHAR(50)   NOT NULL,
    FullName     VARCHAR(100)  NOT NULL,   -- Derived: FirstName + LastName
    Gender       CHAR(1)       NOT NULL,   -- 'M' or 'F'
    BirthDate    DATE          NOT NULL,
    Age          INT           NOT NULL,   -- Calculated in preprocessing
    City         VARCHAR(100)  NOT NULL,
    JoinDate     DATE          NOT NULL,   -- Date customer registered

    CONSTRAINT PK_Customers PRIMARY KEY (CustomerID),
    CONSTRAINT CK_Gender    CHECK (Gender IN ('M', 'F')),
    CONSTRAINT CK_Age       CHECK (Age BETWEEN 16 AND 100)
);
GO

-- ?? 2. Products ??????????????????????????????????????????????
-- Stores product catalog with pricing
CREATE TABLE dbo.Products (
    ProductID    VARCHAR(10)    NOT NULL,   -- e.g. P001
    ProductName  VARCHAR(100)   NOT NULL,
    Category     VARCHAR(50)    NOT NULL,   -- Electronics, Fashion, Groceries
    SubCategory  VARCHAR(50)    NOT NULL,   -- Camera, Footwear, Fruits, etc.
    UnitPrice    DECIMAL(10,2)  NOT NULL,   -- Selling price
    CostPrice    DECIMAL(10,2)  NOT NULL,   -- Purchase/cost price
    ProfitMargin DECIMAL(5,2)   NOT NULL,   -- (UnitPrice-CostPrice)/UnitPrice*100

    CONSTRAINT PK_Products      PRIMARY KEY (ProductID),
    CONSTRAINT CK_UnitPrice     CHECK (UnitPrice > 0),
    CONSTRAINT CK_CostPrice     CHECK (CostPrice > 0),
    CONSTRAINT CK_ProfitMargin  CHECK (ProfitMargin >= 0)
);
GO

-- ?? 3. Stores ????????????????????????????????????????????????
-- Stores branch/location information
CREATE TABLE dbo.Stores (
    StoreID    VARCHAR(10)   NOT NULL,   -- e.g. S001
    StoreName  VARCHAR(100)  NOT NULL,
    City       VARCHAR(100)  NOT NULL,
    Region     VARCHAR(50)   NOT NULL,  -- North, South, East, West, Central

    CONSTRAINT PK_Stores PRIMARY KEY (StoreID)
);
GO

-- ?? 4. Transactions ??????????????????????????????????????????
-- Central fact table — each row is one sale transaction
CREATE TABLE dbo.Transactions (
    TransactionID  VARCHAR(10)    NOT NULL,  -- e.g. T00001
    Date           DATE           NOT NULL,  -- Transaction date
    CustomerID     VARCHAR(10)    NOT NULL,  -- FK ? Customers
    ProductID      VARCHAR(10)    NOT NULL,  -- FK ? Products
    StoreID        VARCHAR(10)    NOT NULL,  -- FK ? Stores
    Quantity       INT            NOT NULL,  -- Items purchased
    Discount       DECIMAL(4,2)   NOT NULL,  -- 0.00 to 0.15 (0% to 15%)
    PaymentMethod  VARCHAR(30)    NOT NULL,  -- Cash / Credit Card / etc.
    TotalAmount    DECIMAL(12,2)  NOT NULL,  -- UnitPrice × Qty × (1?Discount)

    CONSTRAINT PK_Transactions       PRIMARY KEY (TransactionID),
    CONSTRAINT FK_Trans_Customer     FOREIGN KEY (CustomerID) REFERENCES dbo.Customers(CustomerID),
    CONSTRAINT FK_Trans_Product      FOREIGN KEY (ProductID)  REFERENCES dbo.Products(ProductID),
    CONSTRAINT FK_Trans_Store        FOREIGN KEY (StoreID)    REFERENCES dbo.Stores(StoreID),
    CONSTRAINT CK_Quantity           CHECK (Quantity > 0),
    CONSTRAINT CK_Discount           CHECK (Discount >= 0 AND Discount <= 1),
    CONSTRAINT CK_TotalAmount        CHECK (TotalAmount > 0)
);
GO

-- ?? Verification: confirm all tables created ?????????????????
SELECT
    TABLE_NAME,
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_CATALOG = 'RetailSalesDataBase'
ORDER BY TABLE_NAME;
GO

PRINT 'RetailSalesDataBase schema created successfully!';
GO


