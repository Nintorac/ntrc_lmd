SELECT
    {{ dbt_utils.generate_surrogate_key(['artist_hk', 'similar_artist_hk']) }} as link_artist_similar_hk,
    similarity_rank,
    current_timestamp as load_date,
    record_source
FROM {{ ref('_artist_similar_indexed') }}
ORDER BY link_artist_similar_hk