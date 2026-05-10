SELECT
    provider_id,
    first_name,
    last_name,
    npi_number,
    specialty,
    network_status,
    CASE WHEN network_status = 'IN_NETWORK' THEN TRUE ELSE FALSE END    AS is_in_network,
    created_at
FROM {{ source('health_insurance', 'providers') }}
