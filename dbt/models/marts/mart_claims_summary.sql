SELECT
    c.claim_id,
    c.service_date,
    c.claim_date,
    c.status                                AS claim_status,
    c.denial_reason,
    c.amount_billed,
    c.amount_allowed,
    c.amount_paid,
    c.member_responsibility,

    m.member_id,
    m.first_name                            AS member_first_name,
    m.last_name                             AS member_last_name,
    m.plan_type,
    m.age                                   AS member_age,
    m.is_active                             AS member_is_active,

    p.provider_id,
    p.first_name                            AS provider_first_name,
    p.last_name                             AS provider_last_name,
    p.specialty                             AS provider_specialty,
    p.network_status,
    p.is_in_network
FROM {{ ref('stg_claims') }}    c
JOIN {{ ref('stg_members') }}   m ON c.member_id   = m.member_id
JOIN {{ ref('stg_providers') }} p ON c.provider_id = p.provider_id
