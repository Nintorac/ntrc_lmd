WITH h5_tracks AS (
    SELECT DISTINCT
        track_id,
        'lmd_h5' as record_source
    FROM {{ source('bronze_data', 'h5_extract') }}
    WHERE track_id IS NOT NULL
),

match_tracks AS (
    SELECT DISTINCT
        track_id,
        'match_scores' as record_source
    FROM {{ source('bronze_data', 'raw_match_scores') }}
    WHERE track_id IS NOT NULL
    AND track_id NOT IN (SELECT track_id FROM h5_tracks)
),

track_sources AS (
    SELECT * FROM h5_tracks
    UNION ALL
    SELECT * FROM match_tracks
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['track_id']) }} as track_hk,
    track_id,
    current_timestamp as load_date,
    record_source
FROM track_sources
ORDER BY track_hk