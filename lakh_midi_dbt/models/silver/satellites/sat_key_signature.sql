SELECT
    h.key_signature_hk,
    
    -- Descriptive attributes
    r.key_name,
    
    -- Audit fields
    current_timestamp as load_date,
    'ref_key_signatures' as record_source

FROM {{ ref('hub_key_signature') }} h
JOIN {{ ref('ref_key_signatures') }} r ON h.key_signature_id = r.key_signature_id
ORDER BY key_signature_hk