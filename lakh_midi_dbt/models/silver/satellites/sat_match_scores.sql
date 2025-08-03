SELECT
    ltm.link_track_midi_hk,
    
    ms.match_score as score,
    'lmd_matching' as matching_algorithm,
    
    current_timestamp as load_date,
    'match_scores' as record_source

FROM {{ ref('link_track_midi') }} ltm
JOIN {{ source('bronze_data', 'raw_match_scores') }} ms 
    ON ltm.track_hk = (SELECT track_hk FROM {{ ref('hub_track') }} WHERE track_id = ms.track_id)
    AND ltm.midi_hk = (SELECT midi_hk FROM {{ ref('hub_midi_file') }} WHERE midi_md5 = ms.midi_md5)