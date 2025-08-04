SELECT
    {{ dbt_utils.generate_surrogate_key(['key_signature_id']) }} as key_signature_hk,
    key_signature_id,
    current_timestamp as load_date,
    'ref_key_signatures' as record_source
FROM {{ ref('ref_key_signatures') }}
ORDER BY key_signature_hk