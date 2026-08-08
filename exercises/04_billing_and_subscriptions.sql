CREATE TABLE subscription_plans (
    plan_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    plan_name VARCHAR(100) NOT NULL UNIQUE,
    price NUMERIC(12,2) NOT NULL CHECK (price >= 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    billing_interval_days INT NOT NULL DEFAULT 30,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE subscriptions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL,
    plan_id BIGINT NOT NULL REFERENCES subscription_plans(plan_id) ON DELETE RESTRICT,
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
    next_billing_date TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_subscriptions_plan_id ON subscriptions (plan_id);

CREATE INDEX idx_subscriptions_user_active 
ON subscriptions (user_id) 
WHERE (deleted_at IS NULL);

CREATE TABLE gateway_profiles (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE,
    gateway_customer_id VARCHAR(255) NOT NULL,
    card_last_four VARCHAR(4) NOT NULL,
    card_exp_month INT NOT NULL CHECK (card_exp_month BETWEEN 1 AND 12),
    card_exp_year INT NOT NULL CHECK (card_exp_year >= 2026),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_gateway_profiles_user_id ON gateway_profiles (user_id);


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
    WHERE id = p_subscription_id AND deleted_at IS NULL
    FOR UPDATE;

    IF v_status = 'ACTIVE' THEN

        UPDATE subscriptions
        SET next_billing_date = CURRENT_TIMESTAMP + INTERVAL '30 days',
            updated_at = CURRENT_TIMESTAMP
        WHERE id = p_subscription_id;
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE VIEW v_active_customer_subscriptions AS
SELECT 
    s.id AS subscription_id,
    s.user_id,
    sp.plan_name,
    sp.price,
    sp.currency,
    s.status,
    s.next_billing_date
FROM subscriptions s
INNER JOIN subscription_plans sp ON sp.plan_id = s.plan_id
WHERE s.deleted_at IS NULL 
  AND sp.is_active = TRUE;
