WITH midi_sources AS (
    SELECT DISTINCT
        midi_md5,
        'lmd_full' as record_source
    FROM {{ source('bronze_data', 'raw_midi_files') }}
    WHERE midi_md5 IS NOT NULL
    
    UNION
    
    SELECT DISTINCT
        midi_md5,
        'match_scores' as record_source
    FROM {{ source('bronze_data', 'raw_match_scores') }}
    WHERE midi_md5 IS NOT NULL
    
    UNION
    
    SELECT DISTINCT
        midi_md5,
        'md5_paths' as record_source
    FROM {{ source('bronze_data', 'raw_md5_paths') }}
    WHERE midi_md5 IS NOT NULL
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['midi_md5']) }} as midi_hk,
    midi_md5,
    current_timestamp as load_date,
    record_source
FROM midi_sources