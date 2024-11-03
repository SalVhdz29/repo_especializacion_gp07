-- Eliminar la base de datos si ya existe
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'DWH_TOPAZIO')
BEGIN
    DROP DATABASE DWH_TOPAZIO;
END
GO

-- Crear la base de datos
CREATE DATABASE DWH_TOPAZIO;
GO

-- Usar la base de datos creada
USE DWH_TOPAZIO;
GO

-- Limpiar tablas si ya existen
IF OBJECT_ID('fact_sales', 'U') IS NOT NULL
    TRUNCATE TABLE fact_sales;
IF OBJECT_ID('dim_discount', 'U') IS NOT NULL
    TRUNCATE TABLE dim_discount;
IF OBJECT_ID('dim_customer', 'U') IS NOT NULL
    TRUNCATE TABLE dim_customer;
IF OBJECT_ID('dim_store', 'U') IS NOT NULL
    TRUNCATE TABLE dim_store;
IF OBJECT_ID('dim_product', 'U') IS NOT NULL
    TRUNCATE TABLE dim_product;
IF OBJECT_ID('dim_time', 'U') IS NOT NULL
    TRUNCATE TABLE dim_time;

-- Crear las tablas solo si no existen
IF OBJECT_ID('dim_time', 'U') IS NULL
BEGIN
CREATE TABLE dim_time (
    date_key INT PRIMARY KEY,
    fullDate DATE,                 
    dayOfWeek TINYINT,
    dayNumInMonth TINYINT,
    dayNumOverall INT,             
    dayName VARCHAR(9),
    dayAbbrev VARCHAR(3),
    weekDayFlag CHAR(1),
    weekNumInYear TINYINT,
    weekNumOverall INT,            
    weekBeginDate DATE,            
    weekBeginDatekey INT,
    month TINYINT,
    monthNumOverall INT,          
    monthName VARCHAR(9),
    monthAbbrev VARCHAR(3),
    quarter TINYINT,
    year SMALLINT,
    yearmo INT,
    fiscalMonth INT,               
    fiscalQuarter INT,             
    fiscalYear SMALLINT,
    lastDayInMonthFlag CHAR(1),
    sameDayYearAgoDate DATE        
);

END

IF OBJECT_ID('dim_product', 'U') IS NULL
BEGIN
    CREATE TABLE dim_product (
        
        product_id INT IDENTITY(1,1) PRIMARY KEY,
        product_bk INT,
        lote_id VARCHAR(255),
        lote_production_date DATE,
        lote_quantity INT,
        unit_cost DECIMAL(10,2),
        sku VARCHAR(255),
        product_name VARCHAR(255),
        category VARCHAR(255),
        lote_cost DECIMAL(10,2),
        unit_price DECIMAL(10,2)
    );
END

IF OBJECT_ID('dim_store', 'U') IS NULL
BEGIN
    CREATE TABLE dim_store (
        store_id INT IDENTITY(1,1) PRIMARY KEY,
        store_bk INT,
        store_name VARCHAR(255),
        store_location VARCHAR(255),
        region VARCHAR(255),
        store_manager VARCHAR(255)
    );
END

IF OBJECT_ID('dim_customer', 'U') IS NULL
BEGIN
    CREATE TABLE dim_customer (
        customer_id INT IDENTITY(1,1) PRIMARY KEY,
        customer_bk INT,
        customer_name VARCHAR(255),
        customer_address VARCHAR(255),
        customer_city VARCHAR(255),
        customer_region VARCHAR(255),
        customer_email VARCHAR(100),
        customer_segment VARCHAR(100),
        loyalty_status VARCHAR(100),
        updated_at DATETIME DEFAULT GETDATE()
    );
END

GO 

CREATE TRIGGER trg_UpdateDimCustomer
ON dim_customer
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dim_customer
    SET updated_at = GETDATE()
    FROM dim_customer AS dc
    INNER JOIN inserted AS i ON dc.customer_id = i.customer_id;
END;


GO


IF OBJECT_ID('dim_discount', 'U') IS NULL
BEGIN
    CREATE TABLE dim_discount (
        discount_id INT IDENTITY(1,1) PRIMARY KEY,
        discount_bk INT,
        discount_type VARCHAR(255),
        discount_name VARCHAR(255),
        discount_value DECIMAL(10,2),
        discount_details VARCHAR(255),
        valid_from DATE,
        valid_to DATE
    );
END

IF OBJECT_ID('fact_sales', 'U') IS NULL
BEGIN
    CREATE TABLE fact_sales (
        sales_id INT IDENTITY(1,1)  PRIMARY KEY,
        order_id INT,
        order_code VARCHAR(255),
        store_id INT FOREIGN KEY REFERENCES dim_store(store_id),
        product_id INT FOREIGN KEY REFERENCES dim_product(product_id),
        discount_id INT FOREIGN KEY REFERENCES dim_discount(discount_id),
        customer_id INT FOREIGN KEY REFERENCES dim_customer(customer_id),
        time_id INT FOREIGN KEY REFERENCES dim_time(date_key),
        quantity DECIMAL(10,2),
        total_amount DECIMAL(10,2),
        total_discount DECIMAL(10,2),
        total_charged DECIMAL(10,2),
        total_cost DECIMAL(10,2),
        total_profit DECIMAL(10,2),
        payment_method VARCHAR(50),
    );
END

-- Crear la tabla dim_catalog_product
IF OBJECT_ID('dim_catalog_product', 'U') IS NULL
BEGIN
    CREATE TABLE dim_catalog_product (
        product_id INT IDENTITY(1,1) PRIMARY KEY,
        product_bk INT,
        product_name VARCHAR(255),
        category VARCHAR(255),
        sku VARCHAR(255),
        description VARCHAR(255)
    );
END

-- Crear la tabla dim_factory
IF OBJECT_ID('dim_factory', 'U') IS NULL
BEGIN
    CREATE TABLE dim_factory (
        factory_id INT IDENTITY(1,1) PRIMARY KEY,
        factory_bk INT,
        factory_name VARCHAR(255)
    );
END

-- Crear la tabla fact_lote
IF OBJECT_ID('fact_lote', 'U') IS NULL
BEGIN
    CREATE TABLE fact_lote (
        lote_id INT IDENTITY(1,1) PRIMARY KEY,
        lote_bk VARCHAR(255),
        factory_id INT FOREIGN KEY REFERENCES dim_factory(factory_id),
        product_id INT FOREIGN KEY REFERENCES dim_catalog_product(product_id),
        time_id INT FOREIGN KEY REFERENCES dim_time(date_key),
        lote_init_date DATE,
        lote_end_date DATE,
        quantity_produced DECIMAL(10,2),
        production_order_name VARCHAR(255),
        lote_cost DECIMAL(10,2),
        lote_production_time INT,
        date_production_order DATE,
        cantidad INT,
        updated_at DATETIME DEFAULT GETDATE()
    );
END


GO 

CREATE TRIGGER trg_UpdateFactLote
ON fact_lote
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE fact_lote
    SET updated_at = GETDATE()
    FROM fact_lote AS fl
    INNER JOIN inserted AS i ON fl.lote_id = i.lote_id;
END;


GO


-- Crear la tabla dim_workcenter_product
IF OBJECT_ID('dim_workcenter_product', 'U') IS NULL
BEGIN
    CREATE TABLE dim_workcenter_product (
        workcenter_id INT IDENTITY(1,1) PRIMARY KEY,
        workcenter_bk INT,
        workcenter_name VARCHAR(255),
        workcenter_code VARCHAR(255),
        capacity INT
    );
END

-- Crear la tabla fact_inventory_movements
IF OBJECT_ID('fact_inventory_movements', 'U') IS NULL
BEGIN
    CREATE TABLE fact_inventory_movements (
        movement_id INT IDENTITY(1,1) PRIMARY KEY,
        workcenter_id INT FOREIGN KEY REFERENCES dim_workcenter_product(workcenter_id),
        product_id INT FOREIGN KEY REFERENCES dim_product(product_id),
        time_id INT FOREIGN KEY REFERENCES dim_time(date_key),
        production_order_name VARCHAR(255),
        quantity DECIMAL(10,2),
        production_minutes_time DECIMAL(10,2),
        unit_production_time DECIMAL(10,2),
        parallel_capacity INT,


    );
END

IF OBJECT_ID('dbo.LoteCantidadTemporal', 'U') IS NOT NULL
    DROP TABLE dbo.LoteCantidadTemporal;

CREATE TABLE dbo.LoteCantidadTemporal (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    lote_code VARCHAR(255),
    lote_date DATE,
    sku VARCHAR(255),
    cantidad_original DECIMAL(10,2),
    cantidad_disponible DECIMAL(10,2)
);

-- default inserts

SET IDENTITY_INSERT dim_customer ON;
INSERT INTO dim_customer (customer_id, customer_bk, customer_name, customer_address, customer_city, customer_region, customer_email, customer_segment, loyalty_status)
VALUES (0, 0, 'Guest', 'Unknown', 'Unknown', 'Unknown', 'guest@unknown.com', 'Unregistered', 'N/A');
SET IDENTITY_INSERT dim_customer OFF;

SET IDENTITY_INSERT dim_discount ON;
INSERT INTO dim_discount (discount_id, discount_bk, discount_type, discount_name, discount_value, discount_details, valid_from, valid_to)
VALUES (0, 0, 'No Discount', 'No Discount Applied', 0.00, 'No discount applied to this transaction', NULL, NULL);
SET IDENTITY_INSERT dim_discount OFF;


