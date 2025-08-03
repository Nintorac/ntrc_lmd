WITH artist_mbtags_unnested AS (
    SELECT
        a.artist_hk,
        h5.musicbrainz.artist_mbtags,
        h5.musicbrainz.artist_mbtags_count
    FROM {{ ref('hub_artist') }} a
    JOIN {{ source('bronze_data', 'h5_extract') }} h5 ON a.artist_id = h5.metadata.songs.artist_id
    WHERE h5.musicbrainz.artist_mbtags IS NOT NULL
      AND array_length(h5.musicbrainz.artist_mbtags, 1) > 0
    QUALIFY ROW_NUMBER() OVER (PARTITION BY a.artist_hk ORDER BY h5.track_id) = 1
),

artist_mbtags_data AS (
    SELECT
        artist_hk,
        amt.artist_mbtags[i]::VARCHAR as tag,
        amt.artist_mbtags_count[i] as tag_count,
        i as tag_rank,
        current_timestamp as load_date,
        'lmd_h5' as record_source
    FROM artist_mbtags_unnested amt
    CROSS JOIN generate_series(1, array_length(amt.artist_mbtags, 1)) as t(i)
)

SELECT * FROM artist_mbtags_data