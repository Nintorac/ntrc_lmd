WITH release_sources AS (
    SELECT DISTINCT
        metadata.songs.release_7digitalid as release_id,
        'lmd_h5' as record_source
    FROM {{ source('bronze_data', 'h5_extract') }}
    WHERE metadata.songs.release_7digitalid IS NOT NULL
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['release_id']) }} as release_hk,
    release_id,
    current_timestamp as load_date,
    record_source
FROM release_sources