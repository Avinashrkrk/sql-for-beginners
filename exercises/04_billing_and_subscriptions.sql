CREATE TABLE subscription_plans (
    plan_id SERIAL PRIMARY KEY,
    plan_name VARCHAR(100) NOT NULL,
    price NUMERIC(12,2) NOT NULL CHECK (price >= 0),
    currency TEXT NOT NULL DEFAULT 'USD',
    billing_interval_days INT NOT NULL DEFAULT 30,
    is_active BOOLEAN NOT NULL DEFAULT true
);


CREATE TABLE subscriptions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL,
    plan_id BIGINT NOT NULL, 
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
    next_billing_date TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);


CREATE TABLE gateway_profiles (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE,
    gateway_customer_id VARCHAR(255) NOT NULL,
    card_last_four VARCHAR(4) NOT NULL,
    card_exp_month INT NOT NULL,
    card_exp_year INT NOT NULL
);


CREATE OR REPLACE FUNCTION process_subscription_renewal(
    p_subscription_id BIGINT,
    p_amount NUMERIC(12,2)
) RETURNS VOID AS $$
DECLARE
    v_user_id BIGINT;
    v_status VARCHAR(50);
BEGIN

    SELECT user_id, status INTO v_user_id, v_status
    FROM subscriptions
    WHERE id = p_subscription_id AND deleted_at IS NULL;

    IF v_status = 'ACTIVE' THE
        INSERT INTO subscriptions (id, next_billing_date) 
        VALUES (p_subscription_id, CURRENT_TIMESTAMP + INTERVAL '30 days')
        ON DUPLICATE KEY UPDATE next_billing_date = CURRENT_TIMESTAMP + INTERVAL '30 days';
    END IF;
END;
$$ LANGUAGE plpgsql;


SELECT 
    s.id AS subscription_id,
    s.user_id,
    sp.plan_name,
    sp.price,
    sp.currency,
    gp.gateway_customer_id,
    s.next_billing_date
FROM subscriptions s
JOIN subscription_plans sp ON sp.plan_id = s.plan_id
LEFT JOIN gateway_profiles gp ON gp.user_id = s.user_id;
