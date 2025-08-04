SELECT
    {{ dbt_utils.generate_surrogate_key(['mode_id']) }} as mode_hk,
    mode_id,
    current_timestamp as load_date,
    'ref_modes' as record_source
FROM {{ ref('ref_modes') }}
ORDER BY mode_hk