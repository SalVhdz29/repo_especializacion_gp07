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
        loyalty_status VARCHAR(100)
    );
END

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


SET IDENTITY_INSERT dim_customer ON;
INSERT INTO dim_customer (customer_id, customer_bk, customer_name, customer_address, customer_city, customer_region, customer_email, customer_segment, loyalty_status)
VALUES (0, 0, 'Guest', 'Unknown', 'Unknown', 'Unknown', 'guest@unknown.com', 'Unregistered', 'N/A');
SET IDENTITY_INSERT dim_customer OFF;

SET IDENTITY_INSERT dim_discount ON;
INSERT INTO dim_discount (discount_id, discount_bk, discount_type, discount_name, discount_value, discount_details, valid_from, valid_to)
VALUES (0, 0, 'No Discount', 'No Discount Applied', 0.00, 'No discount applied to this transaction', NULL, NULL);
SET IDENTITY_INSERT dim_discount OFF;









-- DIM CATALOG PRODUCT (MAGENTO)

SELECT
    p.entity_id AS product_id,
    pn.value AS product_name,
    catp.category_id,
    cat.value AS category,
    p.sku,
    CAST(REPLACE(REPLACE(pd.value, '<p>', ''), '</p>', '') AS VARCHAR(255)) AS description 
FROM
    catalog_product_entity AS p
LEFT JOIN
    catalog_product_entity_varchar AS pn ON p.entity_id = pn.entity_id
    AND pn.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'name' AND entity_type_id = 4)
LEFT JOIN
    catalog_category_product AS catp ON p.entity_id = catp.product_id
LEFT JOIN
    catalog_category_entity_varchar AS cat ON catp.category_id = cat.entity_id
    AND cat.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'name' AND entity_type_id = 3)
LEFT JOIN
    catalog_category_entity_text AS pd ON p.entity_id = pd.entity_id
    AND pd.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'description' AND entity_type_id = 3)
WHERE
    cat.value IS NOT NULL;  



-- DIM PRODUCT (ODOO)
SELECT  
    mp.id AS orden_id, 
    mp.name AS orden_nombre, 
    mp.state AS estado_orden, 
    mp.product_id AS orden_producto_id, 
    (pt.name ->> 'en_US')::VARCHAR AS nombre_producto_orden,
    pp.default_code as sku,
    mp.product_qty AS cantidad_producida, 
    mp.date_start AS fecha_inicio, 
    mp.date_finished AS fecha_fin,
    
    sm.id AS stock_move_id, 
    sm.product_id AS stock_move_producto_id, 
    sm.product_qty AS cantidad_movimiento, 
    sm.quantity_done AS cantidad_terminada,
    
    sml.id AS stock_move_line_id, 
    sml.product_id AS stock_move_line_producto_id, 
    sml.production_id AS produccion_id_linea, 
    sml.date AS fecha_movimiento, 
    sml.lot_id AS lote_id,
    sl.create_date AS lote_production_date,
    sl.create_date AS lote_date_entera,
    sl.name AS codigo_lote, -- Código de lote
    
    svl.unit_cost AS costo_unitario,
    svl.value AS costo_total_lote,
    sl.company_id AS company_id,
    rc.name AS company_name

FROM 
    public.mrp_production mp

LEFT JOIN public.stock_move sm ON sm.production_id = mp.id 

LEFT JOIN public.stock_move_line sml ON sml.move_id = sm.id 

LEFT JOIN public.stock_valuation_layer svl ON svl.stock_move_id = sm.id 
    AND svl.product_id = sml.product_id

LEFT JOIN public.stock_lot sl ON sl.id = sml.lot_id
    AND sl.product_id = sml.product_id

LEFT JOIN public.res_company rc ON rc.id = sl.company_id

INNER JOIN public.product_product pp ON pp.id = mp.product_id 
INNER JOIN public.product_template pt ON pt.id = pp.product_tmpl_id 

WHERE 
    mp.state = 'done'
    AND sml.product_id = mp.product_id
    and sl.name is not null ;



-- Magento (para obtener el price del producto)
   SELECT 
    cpe.sku,
    cped.value AS price
FROM 
    catalog_product_entity AS cpe
JOIN 
    catalog_product_entity_decimal AS cped 
ON 
    cpe.entity_id = cped.entity_id
WHERE 
    cped.attribute_id = 77; --id del eav para precio.



-- DIM DISCOUNT(magento)
SELECT 
    rule_id,
    'catalog_rule' AS discount_type,
    name AS discount_name,
    description AS discount_details,
    discount_amount AS discount_value,
    'Y' AS active_flag,
    from_date,
    to_date
FROM 
    catalogrule;


-- DIM FACTORY(odoo)

   SELECT 
    id AS factory_id,
    name AS factory_name
FROM 
    res_company;



-- DIM WORKCENTER PRODUCT(odoo)
SELECT 
    wc.id AS workcenter_bk,            
    wc.name AS workcenter_name,
    wc.code AS workcenter_code,
    wc.default_capacity AS capacity,
FROM 
    mrp_workcenter AS wc;



-- DIM CUSTOMER(MAGENTO)
SELECT 
    c.entity_id AS customer_bk,
    CONCAT_WS(' ', c.firstname, c.lastname) AS customer_name,
    COALESCE(ca.street, 'No Address') AS customer_address,
    COALESCE(ca.city, 'No City') AS customer_city,
    COALESCE(ca.region, 'No Region') AS customer_region,
    c.email AS customer_email,
    CASE 
        WHEN COUNT(o.entity_id) = 1 THEN 'Nuevo'
        WHEN COUNT(o.entity_id) BETWEEN 2 AND 5 THEN 'Frecuente'
        WHEN COUNT(o.entity_id) > 5 THEN 'Leal'
        ELSE 'Desconocido'
    END AS customer_segment,
    CASE 
        WHEN DATEDIFF(NOW(), MAX(o.created_at)) <= 180 THEN 'Activo'
        WHEN DATEDIFF(NOW(), MAX(o.created_at)) BETWEEN 181 AND 365 THEN 'Inactivo'
        WHEN DATEDIFF(NOW(), MAX(o.created_at)) > 365 THEN 'Perdido'
        ELSE 'Desconocido'
    END AS loyalty_status
FROM 
    customer_entity AS c
LEFT JOIN 
    customer_address_entity AS ca ON c.entity_id = ca.parent_id
LEFT JOIN 
    sales_order AS o ON c.entity_id = o.customer_id
GROUP BY 
    c.entity_id, c.firstname, c.lastname, ca.street, ca.city, ca.region, c.email;



-- FACT SALES(magento)
SELECT 
    o.entity_id AS order_id,
    o.increment_id AS order_code,
    o.store_id,
    oi.product_id,
    oi.sku AS product_sku,
    COALESCE(o.customer_id, 0) AS customer_id,
    CAST(DATE_FORMAT(o.created_at, '%Y%m%d') AS INT) AS time_id,
    oi.qty_ordered AS quantity,
    oi.row_total AS total_amount,
    oi.discount_amount AS total_discount,
    oi.row_total_incl_tax AS total_charged,
    oi.base_cost AS total_cost,
    (oi.row_total_incl_tax - oi.base_cost - oi.discount_amount) AS total_profit,
    p.method AS payment_method,
    
    COALESCE(sr_coupon.rule_id, sr_name.rule_id) AS discount_rule_id,  
    COALESCE(o.discount_description, 'No Discount Applied') AS discount_applied,
    isi.source_code,

    SUBSTRING(
	    isi.source_code, 
	    LOCATE('-', isi.source_code) + 1, 
	    LOCATE('-', isi.source_code, LOCATE('-', isi.source_code) + 1) - LOCATE('-', isi.source_code) - 1
	) AS LOTEID

FROM 
    sales_order o
JOIN 
    sales_order_item oi ON o.entity_id = oi.order_id
LEFT JOIN 
    sales_order_payment p ON o.entity_id = p.parent_id
LEFT JOIN 
    salesrule_coupon sc ON o.coupon_code = sc.code  
LEFT JOIN 
    salesrule sr_coupon ON sc.rule_id = sr_coupon.rule_id  
LEFT JOIN 
    salesrule sr_name ON o.discount_description = sr_name.name 
LEFT JOIN 
    (
        SELECT source_code, sku
        FROM inventory_source_item
        WHERE sku IS NOT NULL
        ORDER BY RAND()
    ) AS isi ON oi.sku = isi.sku
WHERE oi.product_type = 'configurable'
GROUP BY 
    o.entity_id;





-- Fact Inventory Movements
select
	--datos de la orden de produccion
	mp.id as orden_id, 
	mp.product_id, 
	mp.company_id as fabrica_id, 
	mp."name" as orden_produccion_name,
	mp.date_start,
	-- datos de la orden de trabajo
	wo.id as orden_trabajo_id,
	wo.product_id as producto_orden_trabajo,
	wo."name" as orden_trabajo_name,
	wo.qty_produced,
	wo.date_start AS workorder_datestart,
	wo.date_finished,
	wo.costs_hour, -- costo por hora que tenia el workcenter al momento que se creo la orden
	wo.duration as duracion, --en minutos
	wo.duration_unit as duracion_por_unidad, -- tiempo que se tardo en producir una unidad (en minutos)
	
	-- datos del centro de trabajo,
	wk.id as workcenter_id,
	wk."name" as workcenter_name,
	wk.code as workcenter_code,
	wk.default_capacity,
	wk.costs_hour as workcenter_costs_hour, -- costo por hora que tiene actualmente el workcenter
	
	-- datos de el lote
	sml.lot_id AS lote_id,
	sl.name as codigo_lote,
	(pt.name ->> 'en_US')::VARCHAR AS nombre_producto_orden,
    pp.default_code as sku
	
FROM 
	public.mrp_production mp -- orden de produccion
	inner join public.mrp_workorder wo on wo.production_id = mp.id 
	inner join public.mrp_workcenter wk on wk.id = wo.workcenter_id
	inner join public.stock_move sm ON sm.production_id = mp.id 
	inner join public.stock_move_line sml ON sml.move_id = sm.id 
	inner join public.stock_lot sl on sl.id = sml.lot_id
	INNER JOIN public.product_product pp ON pp.id = mp.product_id 
	INNER JOIN public.product_template pt ON pt.id = pp.product_tmpl_id 
where mp.state = 'done'
AND sml.product_id = mp.product_id;



SELECT 
    dp.lote_id,
    COUNT(fs.order_id) AS order_count
FROM 
    fact_sales fs
JOIN 
    dim_product dp ON fs.product_id = dp.product_id
GROUP BY 
    dp.lote_id
ORDER BY 
    dp.lote_id;
