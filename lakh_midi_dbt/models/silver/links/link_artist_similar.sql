SELECT
    {{ dbt_utils.generate_surrogate_key(['artist_hk', 'similar_artist_hk']) }} as link_artist_similar_hk,
    artist_hk,
    similar_artist_hk,
    current_timestamp as load_date,
    record_source
FROM {{ ref('_artist_similar_indexed') }}