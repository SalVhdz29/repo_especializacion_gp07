-- Dimensión de tiempo
CREATE TABLE dim_time (
    timeId DATE PRIMARY KEY,
    dateKey INT NOT NULL,
    fullDate SMALLDATETIME NOT NULL,
    dayOfWeek TINYINT,
    dayNumInMonth TINYINT,
    dayNumOverall SMALLINT,
    dayName VARCHAR(9),
    dayAbbrev VARCHAR(3),
    weekdayFlag CHAR(1),
    weekNumInYear TINYINT,
    weekNumOverall SMALLINT,
    weekBeginDate SMALLDATETIME,
    weekBeginDateKey SMALLINT,
    month TINYINT,
    monthNumOverall SMALLINT,
    monthName VARCHAR(9),
    monthAbbrev CHAR(3),
    quarter TINYINT,
    year SMALLINT,
    yearmo INT,
    fiscalMonth TINYINT,
    fiscalQuarter TINYINT,
    fiscalYear SMALLINT,
    lastDayInMonthFlag CHAR(1),
    sameDayYearAgoDate SMALLDATETIME
);

-- Dimensión de productos
CREATE TABLE dim_product (
    product_id INT PRIMARY KEY,
    product_bk INT NOT NULL,
    lote_id INT,
    lote_quantity INT,
    lote_production_date DATE,
    unit_price DECIMAL(10, 2),
    category VARCHAR(100),
    product_name VARCHAR(255),
    unit_cost DECIMAL(10, 2)
);

-- Dimensión de ubicaciones
CREATE TABLE dim_location (
    location_id INT PRIMARY KEY,
    location_bk INT NOT NULL,
    location_name VARCHAR(255),
    location_type VARCHAR(50),
    region VARCHAR(50)
);

-- Dimensión de centros de trabajo
CREATE TABLE dim_workcenter (
    workcenter_id INT PRIMARY KEY,
    workcenter_name VARCHAR(255),
    capacity INT
);

-- Dimensión de productos en catálogo
CREATE TABLE dim_catalog_product (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(255),
    category VARCHAR(100),
    description VARCHAR(100)
);

-- Dimensión de clientes
CREATE TABLE dim_customer (
    customer_id INT PRIMARY KEY,
    customer_bk INT NOT NULL,
    customer_name VARCHAR(255),
    customer_address VARCHAR(255),
    customer_city VARCHAR(255),
    customer_region VARCHAR(255),
    customer_email VARCHAR(100),
    customer_segment VARCHAR(100),
    loyalty_status VARCHAR(100)
);

-- Dimensión de tiendas
CREATE TABLE dim_store (
    store_id INT PRIMARY KEY,
    store_name VARCHAR(255),
    store_location VARCHAR(255),
    region VARCHAR(255),
    store_manager VARCHAR(255)
);

-- Hecho de movimientos de inventario
CREATE TABLE fact_inventory_movements (
    movement_id INT PRIMARY KEY,
    product_id INT NOT NULL,
    location_id INT NOT NULL,
    quantity_moved DECIMAL(10, 2),
    quantity_before DECIMAL(10, 2),
    quantity_after DECIMAL(10, 2),
    movement_type VARCHAR(50),
    movement_reason VARCHAR(50),
    movement_date DATE,
    FOREIGN KEY (product_id) REFERENCES dim_product(product_id),
    FOREIGN KEY (location_id) REFERENCES dim_location(location_id)
);

-- Hecho de lotes
CREATE TABLE fact_lote (
    lote_id INT PRIMARY KEY,
    lote_bk INT NOT NULL,
    product_id INT,
    workcenter_id INT,
    quantity_produced DECIMAL(10, 2),
    lote_cost DECIMAL(10, 2),
    lote_init_time DATETIME,
    lote_end_time DATETIME,
    lote_production_time INT,
    production_order_status VARCHAR(50),
    date_production_order DATE,
    batch_status VARCHAR(50),
    status_start_date DATE,
    status_end_date DATE,
    active_status BIT,
    FOREIGN KEY (product_id) REFERENCES dim_product(product_id),
    FOREIGN KEY (workcenter_id) REFERENCES dim_workcenter(workcenter_id)
);

-- Hecho de ventas
CREATE TABLE fact_sales (
    sales_id INT PRIMARY KEY,
    order_id INT,
    store_id INT,
    product_id INT,
    customer_id INT,
    quantity DECIMAL(10, 2),
    total_revenue DECIMAL(10, 2),
    total_cost DECIMAL(10, 2),
    discount DECIMAL(10, 2),
    payment_method VARCHAR(50),
    margin DECIMAL(10, 2),
    order_date DATE,
    FOREIGN KEY (product_id) REFERENCES dim_product(product_id),
    FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id),
    FOREIGN KEY (store_id) REFERENCES dim_store(store_id)
);
