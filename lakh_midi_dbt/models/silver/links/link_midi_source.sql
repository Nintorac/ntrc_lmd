WITH midi_source_links AS (
    SELECT
        m.midi_hk,
        s.source_hk,
        'md5_to_paths' as record_source
    FROM {{ ref('hub_midi_file') }} m
    JOIN {{ source('bronze_data', 'raw_md5_paths') }} mp ON m.midi_md5 = mp.midi_md5
    JOIN {{ ref('hub_midi_source') }} s ON s.source_path = mp.source_path
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['midi_hk', 'source_hk']) }} as link_midi_source_hk,
    midi_hk,
    source_hk,
    current_timestamp as load_date,
    record_source
FROM midi_source_links