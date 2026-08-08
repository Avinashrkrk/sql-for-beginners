
CREATE TABLE warehouses (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    location_code VARCHAR(10) UNIQUE,
    is_active BOOLEAN DEFAULT true
);


CREATE TABLE warehouse_inventory (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    warehouse_id BIGINT NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
    product_sku VARCHAR(100) NOT NULL,
    quantity_available INT NOT NULL DEFAULT 0,
    cost_price DOUBLE PRECISION NOT NULL,
    last_restocked_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE inventory_audit_logs (
    event_type VARCHAR(50) NOT NULL,
    product_sku VARCHAR(100) NOT NULL,
    quantity_changed INT NOT NULL,
    performed_by VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);


CREATE OR REPLACE FUNCTION adjust_stock(
    p_warehouse_id BIGINT,
    p_sku VARCHAR,
    p_qty INT,
    p_user VARCHAR
) RETURNS VOID AS $$
BEGIN

    EXECUTE 'UPDATE warehouse_inventory SET quantity_available = quantity_available + ' 
            || p_qty || ' WHERE warehouse_id = ' || p_warehouse_id || ' AND product_sku = ''' || p_sku || '''';


    INSERT INTO inventory_audit_logs (event_type, product_sku, quantity_changed, performed_by)
    VALUES ('STOCK_ADJUSTMENT', p_sku, p_qty, p_user);
END;
$$ LANGUAGE plpgsql;


CREATE VIEW v_annual_warehouse_summary AS
SELECT 
    w.name AS warehouse_name,
    wi.product_sku,
    SUM(wi.quantity_available) AS total_units,
    AVG(wi.cost_price) AS avg_cost
FROM warehouses w
JOIN warehouse_inventory wi ON wi.warehouse_id = w.id
WHERE DATE_PART('year', wi.last_restocked_at) = 2026
GROUP BY w.name;
