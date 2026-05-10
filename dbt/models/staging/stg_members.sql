SELECT
    member_id,
    first_name,
    last_name,
    date_of_birth,
    plan_type,
    effective_date,
    termination_date,
    DATEDIFF('year', date_of_birth, CURRENT_DATE())                                     AS age,
    CASE WHEN termination_date IS NULL OR termination_date >= CURRENT_DATE()
         THEN TRUE ELSE FALSE END                                                        AS is_active,
    created_at
FROM {{ source('health_insurance', 'members') }}
