SELECT
    ltm.link_track_midi_hk,
    
    LEAST(ms.match_score, 1.0) as score,
    'lmd_matching' as matching_algorithm,
    
    current_timestamp as load_date,
    'match_scores' as record_source

FROM {{ source('bronze_data', 'raw_match_scores') }} ms
JOIN {{ ref('hub_track') }} ht ON ht.track_id = ms.track_id
JOIN {{ ref('hub_midi_file') }} hm ON hm.midi_md5 = ms.midi_md5
JOIN {{ ref('link_track_midi') }} ltm ON ltm.track_hk = ht.track_hk AND ltm.midi_hk = hm.midi_hk
ORDER BY link_track_midi_hk