CREATE OR REPLACE TABLE members (
    member_id       VARCHAR(36)     NOT NULL,
    first_name      VARCHAR(100)    NOT NULL,
    last_name       VARCHAR(100)    NOT NULL,
    date_of_birth   DATE            NOT NULL,
    plan_type       VARCHAR(20)     NOT NULL,   -- HMO, PPO, EPO
    effective_date  DATE            NOT NULL,
    termination_date DATE,
    created_at      TIMESTAMP_NTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_members PRIMARY KEY (member_id),
    CONSTRAINT chk_members_plan_type CHECK (plan_type IN ('HMO', 'PPO', 'EPO'))
);
