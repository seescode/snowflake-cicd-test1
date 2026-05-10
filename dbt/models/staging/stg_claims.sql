SELECT
    claim_id,
    member_id,
    provider_id,
    service_date,
    claim_date,
    status,
    denial_reason,
    amount_billed,
    amount_allowed,
    amount_paid,
    COALESCE(amount_billed - amount_paid, amount_billed)    AS member_responsibility,
    created_at,
    updated_at
FROM {{ source('health_insurance', 'claims') }}
