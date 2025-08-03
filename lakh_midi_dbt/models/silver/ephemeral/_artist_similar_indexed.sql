{{ config(materialized='ephemeral') }}

WITH artist_similar_raw AS (
    SELECT 
        a.artist_hk,
        h5.metadata.similar_artists
    FROM {{ ref('hub_artist') }} a
    JOIN {{ source('bronze_data', 'h5_extract') }} h5 ON a.artist_id = h5.metadata.songs.artist_id
    WHERE h5.metadata.similar_artists IS NOT NULL
      AND array_length(h5.metadata.similar_artists, 1) > 0
    QUALIFY ROW_NUMBER() OVER (PARTITION BY a.artist_hk ORDER BY h5.track_id) = 1
)

SELECT
    asr.artist_hk,
    a2.artist_hk as similar_artist_hk,
    asr.similar_artists[i] as similar_artist_id,
    i as similarity_rank,
    'lmd_h5' as record_source
FROM artist_similar_raw asr
CROSS JOIN generate_series(1, array_length(asr.similar_artists, 1)) as t(i)
JOIN {{ ref('hub_artist') }} a2 ON a2.artist_id = asr.similar_artists[i]