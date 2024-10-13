-- ODOO 16


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


-- MAGENTO 

SELECT
ce.sku
FROM
 catalog_product_entity ce;


SELECT 
    pt.id AS product_id,
    pt.id AS product_bk,
    pt.name AS product_name,
    pc.name AS category
FROM product_template pt
JOIN product_category pc ON pt.categ_id = pc.id;
