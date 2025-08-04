-- Analysis: Find MIDI match scores > 1.0 from bronze data
-- These are outliers that will be clamped to 1.0 in the silver layer

SELECT 
    track_id,
    score,
    midi_md5
FROM {{ source('bronze_data', 'raw_match_scores') }}
WHERE score > 1.0
ORDER BY score DESC