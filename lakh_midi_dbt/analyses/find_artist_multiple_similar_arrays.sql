-- Test to check if artists have multiple different similar_artists arrays
-- This would explain duplicates in our similarity data

SELECT 
    a.artist_hk,
    a.artist_id,
    count(DISTINCT h5.metadata.similar_artists) as distinct_similar_arrays,
    list(distinct h5.metadata.similar_artists) similar_arrays,
    count(*) as total_records
FROM {{ ref('hub_artist') }} a
JOIN {{ source('bronze_data', 'h5_extract') }} h5 ON a.artist_id = h5.metadata.songs.artist_id
WHERE h5.metadata.similar_artists IS NOT NULL
GROUP BY a.artist_hk, a.artist_id
HAVING count(DISTINCT h5.metadata.similar_artists) > 1