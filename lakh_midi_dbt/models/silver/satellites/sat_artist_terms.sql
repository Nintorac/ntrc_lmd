WITH artist_terms_unnested AS (
    SELECT
        a.artist_hk,
        h5.metadata.artist_terms,
        h5.metadata.artist_terms_freq,
        h5.metadata.artist_terms_weight
    FROM {{ ref('hub_artist') }} a
    JOIN {{ source('bronze_data', 'h5_extract') }} h5 ON a.artist_id = h5.metadata.songs.artist_id
    WHERE h5.metadata.artist_terms IS NOT NULL
      AND array_length(h5.metadata.artist_terms, 1) > 0
    QUALIFY ROW_NUMBER() OVER (PARTITION BY a.artist_hk ORDER BY h5.track_id) = 1
),

artist_terms_data AS (
    SELECT
        artist_hk,
        atu.artist_terms[i]::VARCHAR as term,
        atu.artist_terms_freq[i] as frequency,
        atu.artist_terms_weight[i] as weight,
        i as term_rank,
        current_timestamp as load_date,
        'lmd_h5' as record_source
    FROM artist_terms_unnested atu
    CROSS JOIN generate_series(1, array_length(atu.artist_terms, 1)) as t(i)
)

SELECT * FROM artist_terms_data