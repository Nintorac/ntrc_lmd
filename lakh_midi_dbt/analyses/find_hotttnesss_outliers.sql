-- Analysis: Find artist_hotttnesss values > 1.0 from bronze data
-- These are outliers that will be clamped to 1.0 in the silver layer

SELECT 
    metadata.songs.artist_id,
    metadata.songs.artist_name,
    metadata.songs.artist_hotttnesss,
    metadata.songs.song_id,
    metadata.songs.title
FROM {{ source('bronze_data', 'h5_extract') }}
WHERE metadata.songs.artist_hotttnesss > 1.0
ORDER BY metadata.songs.artist_hotttnesss DESC