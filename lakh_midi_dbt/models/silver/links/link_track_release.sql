WITH track_release_links AS (
    SELECT
        t.track_hk,
        r.release_hk,
        'lmd_h5' as record_source
    FROM {{ ref('hub_track') }} t
    JOIN {{ source('bronze_data', 'h5_extract') }} h5 ON t.track_id = h5.track_id
    JOIN {{ ref('hub_release') }} r ON r.release_id = h5.metadata.songs.release_7digitalid
    WHERE h5.metadata.songs.release_7digitalid IS NOT NULL
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['track_hk', 'release_hk']) }} as link_track_release_hk,
    track_hk,
    release_hk,
    current_timestamp as load_date,
    record_source
FROM track_release_links
ORDER BY link_track_release_hk