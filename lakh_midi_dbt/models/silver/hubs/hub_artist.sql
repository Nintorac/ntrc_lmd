WITH main_artist_sources AS (
    SELECT DISTINCT
        metadata.songs.artist_id::varchar as artist_id,
        'lmd_h5' as record_source
    FROM {{ source('bronze_data', 'h5_extract') }}
    WHERE metadata.songs.artist_id IS NOT NULL
),

similar_artists AS (
    select DISTINCT 
        artist_id,
        'lmd_h5_similarity' as record_source
    FROM (
        select UNNEST(metadata.similar_artists)::varchar as artist_id 
        from {{ source('bronze_data', 'h5_extract') }}
        WHERE metadata.similar_artists IS NOT NULL
    ) h5
    where artist_id not in 
        (select artist_id from main_artist_sources)
),

artist_sources as (
    select * from main_artist_sources
    union 
    select * from similar_artists
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['artist_id']) }} as artist_hk,
    artist_id,
    current_timestamp as load_date,
    record_source
FROM artist_sources