WITH artist_sources AS (
    SELECT DISTINCT
        metadata.songs.artist_id as artist_id,
        'lmd_h5' as record_source
    FROM {{ source('bronze_data', 'h5_extract') }}
    WHERE metadata.songs.artist_id IS NOT NULL
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['artist_id']) }} as artist_hk,
    artist_id,
    current_timestamp as load_date,
    record_source
FROM artist_sources