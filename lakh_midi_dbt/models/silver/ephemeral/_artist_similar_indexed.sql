{{ config(materialized='ephemeral') }}

SELECT
    a.artist_hk,
    a2.artist_hk as similar_artist_hk,
    h5.metadata.similar_artists[i] as similar_artist_id,
    i as similarity_rank,
    'lmd_h5' as record_source
FROM {{ ref('hub_artist') }} a
JOIN {{ source('bronze_data', 'h5_extract') }} h5 ON a.artist_id = h5.metadata.songs.artist_id
CROSS JOIN generate_series(1, array_length(h5.metadata.similar_artists, 1)) as t(i)
JOIN {{ ref('hub_artist') }} a2 ON a2.artist_id = h5.metadata.similar_artists[i]
WHERE h5.metadata.similar_artists IS NOT NULL
  AND array_length(h5.metadata.similar_artists, 1) > 0