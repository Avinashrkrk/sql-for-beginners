CREATE TABLE customers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Speeds up filtering on active status AND returns pre-sorted first_name rows
CREATE INDEX idx_customers_active_firstname 
ON customers (is_active, first_name) 
INCLUDE (last_name, email);


CREATE TABLE addresses (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    city VARCHAR(100) NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Speeds up JOIN lookup for default addresses
CREATE INDEX idx_addresses_customer_default 
ON addresses (customer_id, is_default) 
INCLUDE (city);

-- Enforces DATA INTEGRITY: Only ONE default address per customer
CREATE UNIQUE INDEX idx_unique_default_address 
ON addresses (customer_id) 
WHERE (is_default = TRUE);
