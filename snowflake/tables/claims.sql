CREATE OR REPLACE TABLE claims (
    claim_id        VARCHAR(36)     NOT NULL,
    member_id       VARCHAR(36)     NOT NULL,
    provider_id     VARCHAR(36)     NOT NULL,
    service_date    DATE            NOT NULL,
    claim_date      DATE            NOT NULL,
    amount_billed   NUMBER(12, 2)   NOT NULL,
    amount_allowed  NUMBER(12, 2),
    amount_paid     NUMBER(12, 2),
    status          VARCHAR(20)     NOT NULL DEFAULT 'PENDING',  -- PENDING, APPROVED, DENIED, PAID
    denial_reason   VARCHAR(500),
    created_at      TIMESTAMP_NTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    updated_at      TIMESTAMP_NTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_claims PRIMARY KEY (claim_id),
    CONSTRAINT fk_claims_member FOREIGN KEY (member_id) REFERENCES members (member_id),
    CONSTRAINT fk_claims_provider FOREIGN KEY (provider_id) REFERENCES providers (provider_id),
    CONSTRAINT chk_claims_status CHECK (status IN ('PENDING', 'APPROVED', 'DENIED', 'PAID')),
    CONSTRAINT chk_claims_amount_billed CHECK (amount_billed > 0)
);
