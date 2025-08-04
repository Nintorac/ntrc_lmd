WITH artist_base AS (
    SELECT
        a.artist_hk,
        a.artist_id,
        sa.artist_name,
        sa.artist_mbid,
        sa.artist_familiarity,
        sa.artist_hotttnesss,
        sa.artist_latitude,
        sa.artist_longitude,
        sa.artist_location,
        sa.artist_7digitalid,
        sa.artist_playmeid
    FROM {{ ref('hub_artist') }} a
    INNER JOIN (
        SELECT 
            artist_hk,
            artist_name,
            artist_mbid,
            artist_familiarity,
            artist_hotttnesss,
            artist_latitude,
            artist_longitude,
            artist_location,
            artist_7digitalid,
            artist_playmeid,
            ROW_NUMBER() OVER (PARTITION BY artist_hk ORDER BY load_date DESC) as rn
        FROM {{ ref('sat_artist') }}
        WHERE artist_name IS NOT NULL
    ) sa ON a.artist_hk = sa.artist_hk AND sa.rn = 1
),

artist_track_metrics AS (
    SELECT
        ab.artist_hk,
        COUNT(DISTINCT lta.track_hk) as total_tracks,
        AVG(st.danceability) as avg_danceability,
        AVG(st.energy) as avg_energy,
        AVG(st.tempo) as avg_tempo,
        AVG(st.loudness) as avg_loudness,
        AVG(st.duration) as avg_duration,
        AVG(st.song_hotttnesss) as avg_song_hotttnesss,
        (SELECT key_signature_id FROM (
            SELECT st.key_signature_id, COUNT(*) as cnt 
            FROM {{ ref('link_track_artist') }} lta2 
            JOIN {{ ref('sat_track') }} st ON lta2.track_hk = st.track_hk 
            WHERE lta2.artist_hk = ab.artist_hk AND st.key_signature_id IS NOT NULL
            GROUP BY st.key_signature_id 
            ORDER BY cnt DESC, st.key_signature_id ASC 
            LIMIT 1
        )) as most_common_key,
        (SELECT time_signature FROM (
            SELECT st.time_signature, COUNT(*) as cnt 
            FROM {{ ref('link_track_artist') }} lta2 
            JOIN {{ ref('sat_track') }} st ON lta2.track_hk = st.track_hk 
            WHERE lta2.artist_hk = ab.artist_hk AND st.time_signature IS NOT NULL
            GROUP BY st.time_signature 
            ORDER BY cnt DESC, st.time_signature ASC 
            LIMIT 1
        )) as most_common_time_signature,
        (SELECT mode_id FROM (
            SELECT st.mode_id, COUNT(*) as cnt 
            FROM {{ ref('link_track_artist') }} lta2 
            JOIN {{ ref('sat_track') }} st ON lta2.track_hk = st.track_hk 
            WHERE lta2.artist_hk = ab.artist_hk AND st.mode_id IS NOT NULL
            GROUP BY st.mode_id 
            ORDER BY cnt DESC, st.mode_id ASC 
            LIMIT 1
        )) as most_common_mode,
        COUNT(DISTINCT CASE WHEN st.year > 1900 AND st.year <= 2100 THEN st.year END) as years_active_count,
        MIN(CASE WHEN st.year > 1900 AND st.year <= 2100 THEN st.year END) as earliest_year,
        MAX(CASE WHEN st.year > 1900 AND st.year <= 2100 THEN st.year END) as latest_year
    FROM artist_base ab
    LEFT JOIN {{ ref('link_track_artist') }} lta ON ab.artist_hk = lta.artist_hk
    LEFT JOIN {{ ref('sat_track') }} st ON lta.track_hk = st.track_hk
    GROUP BY ab.artist_hk
),

artist_top_terms AS (
    SELECT
        artist_hk,
        array_agg(term ORDER BY weight DESC) as top_terms,
        array_agg(weight ORDER BY weight DESC) as top_term_weights,
        array_agg(frequency ORDER BY weight DESC) as top_term_frequencies
    FROM (
        SELECT 
            artist_hk, 
            term, 
            weight, 
            frequency,
            ROW_NUMBER() OVER (PARTITION BY artist_hk ORDER BY weight DESC) as rn
        FROM {{ ref('sat_artist_terms') }}
    ) ranked
    WHERE rn <= 10
    GROUP BY artist_hk
),

artist_top_mbtags AS (
    SELECT
        artist_hk,
        array_agg(tag ORDER BY tag_count DESC) as top_mbtags,
        array_agg(tag_count ORDER BY tag_count DESC) as top_mbtag_counts
    FROM (
        SELECT 
            artist_hk, 
            tag, 
            tag_count,
            ROW_NUMBER() OVER (PARTITION BY artist_hk ORDER BY tag_count DESC) as rn
        FROM {{ ref('sat_artist_mbtags') }}
    ) ranked
    WHERE rn <= 10
    GROUP BY artist_hk
),

artist_similarity_metrics AS (
    SELECT
        artist_hk,
        COUNT(*) as similar_artists_count,
        AVG(CASE WHEN sas.similarity_rank <= 10 THEN sas.similarity_rank END) as avg_top10_similarity_rank
    FROM {{ ref('link_artist_similar') }} las
    LEFT JOIN {{ ref('sat_artist_similarity') }} sas ON las.link_artist_similar_hk = sas.link_artist_similar_hk
    GROUP BY artist_hk
),

artist_midi_quality AS (
    SELECT
        ab.artist_hk,
        COUNT(DISTINCT ltm.midi_hk) as total_midi_matches,
        AVG(sms.score) as avg_midi_match_score,
        COUNT(CASE WHEN sms.score >= 0.8 THEN 1 END) as high_quality_matches,
        COUNT(CASE WHEN sms.score >= 0.6 AND sms.score < 0.8 THEN 1 END) as medium_quality_matches,
        COUNT(CASE WHEN sms.score < 0.6 THEN 1 END) as low_quality_matches
    FROM artist_base ab
    LEFT JOIN {{ ref('link_track_artist') }} lta ON ab.artist_hk = lta.artist_hk
    LEFT JOIN {{ ref('link_track_midi') }} ltm ON lta.track_hk = ltm.track_hk
    LEFT JOIN {{ ref('sat_match_scores') }} sms ON ltm.link_track_midi_hk = sms.link_track_midi_hk
    GROUP BY ab.artist_hk
)

SELECT
    ab.artist_hk,
    ab.artist_id,
    ab.artist_name,
    ab.artist_mbid,
    ab.artist_familiarity,
    ab.artist_hotttnesss,
    ab.artist_location,
    ab.artist_latitude,
    ab.artist_longitude,
    ab.artist_7digitalid,
    ab.artist_playmeid,
    
    -- Track portfolio metrics
    COALESCE(atm.total_tracks, 0) as total_tracks,
    atm.years_active_count,
    atm.earliest_year,
    atm.latest_year,
    
    -- Musical characteristics (averages across catalog)
    ROUND(atm.avg_danceability, 3) as avg_danceability,
    ROUND(atm.avg_energy, 3) as avg_energy,
    ROUND(atm.avg_tempo, 1) as avg_tempo,
    ROUND(atm.avg_loudness, 2) as avg_loudness,
    ROUND(atm.avg_duration, 1) as avg_duration,
    ROUND(atm.avg_song_hotttnesss, 3) as avg_song_hotttnesss,
    atm.most_common_key,
    atm.most_common_time_signature,
    atm.most_common_mode,
    
    -- Artist terms and tags (top 10 by weight/count)
    att.top_terms,
    att.top_term_weights,
    att.top_term_frequencies,
    amt.top_mbtags,
    amt.top_mbtag_counts,
    
    -- Network metrics
    COALESCE(asm.similar_artists_count, 0) as similar_artists_count,
    asm.avg_top10_similarity_rank,
    
    -- MIDI matching quality
    COALESCE(amq.total_midi_matches, 0) as total_midi_matches,
    ROUND(amq.avg_midi_match_score, 3) as avg_midi_match_score,
    COALESCE(amq.high_quality_matches, 0) as high_quality_matches,
    COALESCE(amq.medium_quality_matches, 0) as medium_quality_matches,
    COALESCE(amq.low_quality_matches, 0) as low_quality_matches,
    
    -- Quality tiers
    CASE 
        WHEN ab.artist_familiarity >= 0.8 AND ab.artist_hotttnesss >= 0.8 THEN 'High Profile'
        WHEN ab.artist_familiarity >= 0.6 AND ab.artist_hotttnesss >= 0.6 THEN 'Medium Profile'
        WHEN ab.artist_familiarity IS NOT NULL AND ab.artist_hotttnesss IS NOT NULL THEN 'Low Profile'
        ELSE 'Unknown Profile'
    END as artist_profile_tier,
    
    CASE 
        WHEN atm.total_tracks >= 20 THEN 'Prolific'
        WHEN atm.total_tracks >= 10 THEN 'Active'
        WHEN atm.total_tracks >= 5 THEN 'Moderate'
        WHEN atm.total_tracks >= 1 THEN 'Limited'
        ELSE 'No Tracks'
    END as catalog_size_tier,
    
    current_timestamp as created_at

FROM artist_base ab
LEFT JOIN artist_track_metrics atm ON ab.artist_hk = atm.artist_hk
LEFT JOIN artist_top_terms att ON ab.artist_hk = att.artist_hk
LEFT JOIN artist_top_mbtags amt ON ab.artist_hk = amt.artist_hk
LEFT JOIN artist_similarity_metrics asm ON ab.artist_hk = asm.artist_hk
LEFT JOIN artist_midi_quality amq ON ab.artist_hk = amq.artist_hk
ORDER BY ab.artist_hk