WITH track_midi_links AS (
    SELECT
        t.track_hk,
        m.midi_hk,
        'match_scores' as record_source
    FROM {{ ref('hub_track') }} t
    JOIN {{ source('bronze_data', 'raw_match_scores') }} ms ON t.track_id = ms.track_id
    JOIN {{ ref('hub_midi_file') }} m ON m.midi_md5 = ms.midi_md5
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['track_hk', 'midi_hk']) }} as link_track_midi_hk,
    track_hk,
    midi_hk,
    current_timestamp as load_date,
    record_source
FROM track_midi_links