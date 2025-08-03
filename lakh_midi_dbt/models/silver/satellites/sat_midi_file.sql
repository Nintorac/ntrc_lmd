{{ config(
        tags=['incremental'],
        options={
            'partition_by': 'partition_col',
            'OVERWRITE_OR_IGNORE': true
        }
    )
}}
SELECT
    m.midi_hk,
    
    mf.file_content,
    mf.file_size_bytes as file_size,
    
    current_timestamp as load_date,
    'lmd_full' as record_source,
    
    -- Operational fields
    substring(midi_hk, 1, 1) partition_col

FROM {{ ref('hub_midi_file') }} m
JOIN {{ source('bronze_data', 'raw_midi_files') }} mf ON m.midi_md5 = mf.midi_md5
where partition_col='{{ var("partition_filter", "a") }}'