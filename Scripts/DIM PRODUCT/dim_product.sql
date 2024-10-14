-- dim store
SELECT
    s.store_id,
    s.name AS store_name,
    (SELECT value FROM core_config_data WHERE path = CONCAT('stores/', s.store_id, '/general/store_information/street_address')) AS address,
    (SELECT value FROM core_config_data WHERE path = CONCAT('stores/', s.store_id, '/general/store_information/city')) AS city,
    (SELECT value FROM core_config_data WHERE path = CONCAT('stores/', s.store_id, '/general/store_information/region_id')) AS region,
    (SELECT value FROM core_config_data WHERE path = CONCAT('stores/', s.store_id, '/general/store_information/manager_name')) AS manager_name
FROM
    store s;

-- dim product

SELECT 
    mp.id AS lote_id, 
    mp.product_id AS product_id, 
    mp.date_finished AS lote_production_date, 
    mp.product_qty AS lote_quantity, 
    pt.name AS product_name, 
    pc.name AS category, 
    pt.list_price AS unit_price,
    -- Cálculo del costo de materiales por separado
    SUM(smv.price_unit * smv.product_qty) AS material_cost, 
    -- Cálculo de costos adicionales por separado
    mp.extra_cost AS additional_cost,
    -- Cálculo del costo unitario de producción (materiales + costos adicionales)
    (
        SUM(smv.price_unit * smv.product_qty) + -- Costo de materiales
        mp.extra_cost -- Costos adicionales registrados en la orden de producción
    ) / mp.product_qty AS unit_production_cost
FROM 
    mrp_production mp
LEFT JOIN 
    product_template pt ON mp.product_id = pt.id
LEFT JOIN 
    product_category pc ON pt.categ_id = pc.id
LEFT JOIN 
    stock_move smv ON mp.id = smv.production_id
LEFT JOIN 
    stock_location sl ON smv.location_id = sl.id -- Relación con la tabla de ubicaciones de origen
LEFT JOIN 
    stock_location sld ON smv.location_dest_id = sld.id -- Relación con la tabla de ubicaciones de destino
WHERE 
    sl.usage = 'internal' -- Ubicación de materiales (WH/Stock)
    AND sld.usage = 'production' -- Ubicación de producción (Production)
GROUP BY 
    mp.id, pt.id, pc.id, mp.product_qty, mp.extra_cost
ORDER BY 
    mp.date_finished, mp.id;



-- dim catalog product
SELECT 
    pt.id AS product_id,
    pt.id AS product_bk,
    pt.name AS product_name,
    pc.name AS category
FROM product_template pt
JOIN product_category pc ON pt.categ_id = pc.id;

--dim workcenter product
SELECT 
    wc.id AS workcenter_id,
    wc.name AS workcenter_name,
    wcc.capacity,               
    pt.id AS product_id,
    pt.name AS product_name,
    pc.name AS category,        
    pt.description_sale AS description 
FROM 
    mrp_workcenter wc
JOIN 
    mrp_workcenter_capacity wcc ON wc.id = wcc.workcenter_id  
JOIN 
    product_template pt ON wcc.product_id = pt.id              
JOIN 
    product_category pc ON pt.categ_id = pc.id;


-- dim location

-- select workcenter
SELECT 
    wc.id AS location_bk,                -- ID del centro de trabajo (workcenter)
    wc.name AS location_name,            -- Nombre del centro de trabajo
    CAST('Centro' AS VARCHAR(50)) AS location_type,           -- Definir tipo como "Centro"
    'N/A' AS region -- Región del centro de trabajo, si no existe, poner "N/A"
FROM 
    mrp_workcenter wc;

-- select stores magento

SELECT 
    store.store_id AS location_bk,             -- ID de la tienda (store)
    store.name AS location_name,         -- Nombre de la tienda
    CAST('Tienda' AS CHAR(50) COLLATE latin1_general_ci) AS location_type,-- Definir tipo como "Tienda"
    (SELECT value FROM core_config_data WHERE path = CONCAT('stores/', store.store_id, '/general/store_information/region_id')) AS region
FROM 
    store store;