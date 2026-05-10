CREATE OR REPLACE TABLE providers (
    provider_id     VARCHAR(36)     NOT NULL,
    first_name      VARCHAR(100)    NOT NULL,
    last_name       VARCHAR(100)    NOT NULL,
    npi_number      VARCHAR(10)     NOT NULL,
    specialty       VARCHAR(50)     NOT NULL,   -- PRIMARY_CARE, CARDIOLOGY, ORTHOPEDICS, etc.
    network_status  VARCHAR(20)     NOT NULL,   -- IN_NETWORK, OUT_OF_NETWORK
    created_at      TIMESTAMP_NTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_providers PRIMARY KEY (provider_id),
    CONSTRAINT uq_providers_npi UNIQUE (npi_number),
    CONSTRAINT chk_providers_network_status CHECK (network_status IN ('IN_NETWORK', 'OUT_OF_NETWORK'))
);
