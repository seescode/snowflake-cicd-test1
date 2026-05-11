CREATE OR REPLACE PROCEDURE <%db%>.<%schema%>.process_claim(claim_id VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE
    v_member_id         VARCHAR;
    v_provider_id       VARCHAR;
    v_amount_billed     NUMBER(12, 2);
    v_plan_type         VARCHAR;
    v_termination_date  DATE;
    v_network_status    VARCHAR;
    v_amount_allowed    NUMBER(12, 2);
    v_amount_paid       NUMBER(12, 2);
    v_denial_reason     VARCHAR;
    v_new_status        VARCHAR;
BEGIN
    -- Load the claim
    SELECT member_id, provider_id, amount_billed
    INTO :v_member_id, :v_provider_id, :v_amount_billed
    FROM claims
    WHERE claims.claim_id = :claim_id
      AND status = 'PENDING';

    IF (v_member_id IS NULL) THEN
        RETURN 'ERROR: Claim not found or not in PENDING status';
    END IF;

    -- Validate member eligibility
    SELECT plan_type, termination_date
    INTO :v_plan_type, :v_termination_date
    FROM members
    WHERE member_id = :v_member_id;

    IF (v_termination_date IS NOT NULL AND v_termination_date < CURRENT_DATE()) THEN
        UPDATE claims
        SET status        = 'DENIED',
            denial_reason = 'Member coverage terminated on ' || v_termination_date::VARCHAR,
            updated_at    = CURRENT_TIMESTAMP()
        WHERE claims.claim_id = :claim_id;
        RETURN 'DENIED: Member coverage terminated';
    END IF;

    -- Validate provider network status
    SELECT network_status
    INTO :v_network_status
    FROM providers
    WHERE provider_id = :v_provider_id;

    IF (v_network_status = 'OUT_OF_NETWORK') THEN
        -- Out-of-network: allow 60% of billed, member pays 40%
        v_amount_allowed := v_amount_billed * 0.60;
        v_amount_paid    := v_amount_allowed * 0.60;
        v_new_status     := 'APPROVED';
        v_denial_reason  := NULL;
    ELSE
        -- In-network: apply plan-type reimbursement rates
        IF (v_plan_type = 'HMO') THEN
            v_amount_allowed := v_amount_billed * 0.90;
            v_amount_paid    := v_amount_allowed * 0.80;
        ELSEIF (v_plan_type = 'PPO') THEN
            v_amount_allowed := v_amount_billed * 0.85;
            v_amount_paid    := v_amount_allowed * 0.70;
        ELSE
            -- EPO
            v_amount_allowed := v_amount_billed * 0.80;
            v_amount_paid    := v_amount_allowed * 0.75;
        END IF;
        v_new_status    := 'APPROVED';
        v_denial_reason := NULL;
    END IF;

    UPDATE claims
    SET status         = :v_new_status,
        amount_allowed = :v_amount_allowed,
        amount_paid    = :v_amount_paid,
        denial_reason  = :v_denial_reason,
        updated_at     = CURRENT_TIMESTAMP()
    WHERE claims.claim_id = :claim_id;

    RETURN v_new_status || ': allowed=' || v_amount_allowed::VARCHAR || ' paid=' || v_amount_paid::VARCHAR;
END;
$$;
