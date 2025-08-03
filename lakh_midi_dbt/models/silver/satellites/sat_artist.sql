SELECT
    a.artist_hk,
    
    h5.metadata.songs.artist_name,
    h5.metadata.songs.artist_mbid,
    h5.metadata.songs.artist_familiarity,
    h5.metadata.songs.artist_hotttnesss,
    h5.metadata.songs.artist_latitude,
    h5.metadata.songs.artist_longitude,
    h5.metadata.songs.artist_location,
    h5.metadata.songs.artist_7digitalid,
    h5.metadata.songs.artist_playmeid,
    
    current_timestamp as load_date,
    'lmd_h5' as record_source

FROM {{ ref('hub_artist') }} a
JOIN {{ source('bronze_data', 'h5_extract') }} h5 ON a.artist_id = h5.metadata.songs.artist_id
ORDER BY artist_hk