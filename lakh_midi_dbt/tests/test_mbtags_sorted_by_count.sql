-- Test to verify that MusicBrainz tags are sorted by tag_count DESC in source arrays
-- This validates our assumption that tag_rank (array position) corresponds to popularity

WITH mbtags_with_next AS (
    SELECT 
        artist_hk,
        tag,
        tag_count,
        tag_rank,
        LEAD(tag_count) OVER (PARTITION BY artist_hk ORDER BY tag_rank) as next_tag_count
    FROM {{ ref('sat_artist_mbtags') }}
),

mbtags_ordering_violations AS (
    SELECT 
        artist_hk,
        tag,
        tag_count,
        tag_rank,
        next_tag_count
    FROM mbtags_with_next
    WHERE next_tag_count IS NOT NULL
      AND tag_count < next_tag_count  -- Current tag_count should be >= next tag_count
)

SELECT * FROM mbtags_ordering_violations