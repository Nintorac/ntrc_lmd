WITH midi_source_sources AS (
    SELECT DISTINCT
        source_path,
        'md5_to_paths' as record_source
    FROM {{ source('bronze_data', 'raw_md5_paths') }}
    WHERE source_path IS NOT NULL
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['source_path']) }} as source_hk,
    source_path,
    current_timestamp as load_date,
    record_source
FROM midi_source_sources
ORDER BY source_hk