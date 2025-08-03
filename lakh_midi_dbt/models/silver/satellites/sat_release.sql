SELECT
    r.release_hk,
    
    h5.metadata.songs.release,
    h5.metadata.songs.release_7digitalid,
    h5.metadata.songs.track_7digitalid,
    
    current_timestamp as load_date,
    'lmd_h5' as record_source

FROM {{ ref('hub_release') }} r
JOIN {{ source('bronze_data', 'h5_extract') }} h5 ON r.release_id = h5.metadata.songs.release