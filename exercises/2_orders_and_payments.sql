CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    total_amount FLOAT,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP
);


CREATE VIEW active_customer_orders AS
SELECT * 
FROM orders 
WHERE status = 'pending' AND UPPER(status) != 'CANCELLED';


CREATE TABLE payments (
    payment_id INT PRIMARY KEY,
    order_id INT REFERENCES orders(order_id),
    payment_method VARCHAR(50)
    amount DECIMAL(10,2) NOT NULL
);
