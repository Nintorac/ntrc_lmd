-- Test for:
--  duplicates in artist similarity data
--  that similarity ranks are consecutive (no gaps)
select 
    artist_hk,
    count(*) as actual_count,
    max(similarity_rank) as max_rank,
    count(*) = max(similarity_rank) as ranks_consecutive
from {{ ref('sat_artist_similarity') }} s
join {{ ref('link_artist_similar') }} l using (link_artist_similar_hk)
group by artist_hk
having actual_count!=max_rank