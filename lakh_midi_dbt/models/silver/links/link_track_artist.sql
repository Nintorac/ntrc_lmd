WITH track_artist_links AS (
    SELECT
        t.track_hk,
        a.artist_hk,
        'lmd_h5' as record_source
    FROM {{ ref('hub_track') }} t
    JOIN {{ source('bronze_data', 'h5_extract') }} h5 ON t.track_id = h5.track_id
    JOIN {{ ref('hub_artist') }} a ON a.artist_id = h5.metadata.songs.artist_id
    WHERE h5.metadata.songs.artist_id IS NOT NULL
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['track_hk', 'artist_hk']) }} as link_track_artist_hk,
    track_hk,
    artist_hk,
    current_timestamp as load_date,
    record_source
FROM track_artist_links