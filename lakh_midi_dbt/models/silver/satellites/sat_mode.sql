SELECT
    h.mode_hk,
    
    -- Descriptive attributes
    r.mode_name,
    
    -- Audit fields
    current_timestamp as load_date,
    'ref_modes' as record_source

FROM {{ ref('hub_mode') }} h
JOIN {{ ref('ref_modes') }} r ON h.mode_id = r.mode_id
ORDER BY mode_hk