SELECT
    m.midi_hk,
    
    mf.file_content,
    mf.file_size_bytes as file_size,
    
    current_timestamp as load_date,
    'lmd_full' as record_source

FROM {{ ref('hub_midi_file') }} m
JOIN {{ source('bronze_data', 'raw_midi_files') }} mf ON m.midi_md5 = mf.midi_md5