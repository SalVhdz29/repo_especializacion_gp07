






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
    '' AS LOTEID

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
AND sml.product_id = mp.product_id
AND ;



SELECT 
    dp.lote_id,
    SUM(fs.quantity) AS total_quantity
FROM 
    fact_sales fs
JOIN 
    dim_product dp ON fs.product_id = dp.product_id
GROUP BY 
    dp.lote_id
ORDER BY 
    dp.lote_id;



UPDATE dim_customer
SET customer_segment = ?, 
    loyalty_status = ?
WHERE customer_bk = ?


-- FACT LOTE
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
    and sl.name is not null 
    AND mp.date_start is not null;
