CREATE OR REPLACE VIEW vw_claims_summary AS
SELECT
    c.claim_id,
    c.service_date,
    c.claim_date,
    c.status,
    c.amount_billed,
    c.amount_allowed,
    c.amount_paid,
    c.denial_reason,

    m.member_id,
    m.first_name                        AS member_first_name,
    m.last_name                         AS member_last_name,
    m.plan_type,

    p.provider_id,
    p.first_name                        AS provider_first_name,
    p.last_name                         AS provider_last_name,
    p.specialty,
    p.network_status
FROM claims c
JOIN members  m ON c.member_id   = m.member_id
JOIN providers p ON c.provider_id = p.provider_id;
