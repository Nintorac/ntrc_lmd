WITH track_base AS (
    SELECT
        t.track_hk,
        t.track_id,
        
        -- Audio analysis features
        st.audio_md5,
        st.analysis_sample_rate,
        st.danceability,
        st.duration,
        st.end_of_fade_in,
        st.energy,
        st.key_signature_id,
        st.key_confidence,
        st.loudness,
        st.mode_id,
        st.mode_confidence,
        st.start_of_fade_out,
        st.tempo,
        st.time_signature,
        st.time_signature_confidence,
        
        -- Track metadata
        st.title,
        st.genre,
        st.year,
        st.analyzer_version,
        st.song_id,
        st.song_hotttnesss,
        
        -- Time series summary stats
        array_length(st.bars_start) as bars_count,
        array_length(st.beats_start) as beats_count,
        array_length(st.sections_start) as sections_count,
        array_length(st.segments_start) as segments_count,
        array_length(st.tatums_start) as tatums_count,
        
        CASE 
            WHEN st.bars_confidence IS NOT NULL AND array_length(st.bars_confidence) > 0
            THEN list_avg(st.bars_confidence)
            ELSE NULL 
        END as avg_bars_confidence,
        
        CASE 
            WHEN st.beats_confidence IS NOT NULL AND array_length(st.beats_confidence) > 0
            THEN list_avg(st.beats_confidence)
            ELSE NULL 
        END as avg_beats_confidence,
        
        CASE 
            WHEN st.segments_confidence IS NOT NULL AND array_length(st.segments_confidence) > 0
            THEN list_avg(st.segments_confidence)
            ELSE NULL 
        END as avg_segments_confidence,
        
        -- Human-readable key/mode names
        sks.key_name,
        sm.mode_name
        
    FROM {{ ref('hub_track') }} t
    LEFT JOIN {{ ref('sat_track') }} st ON t.track_hk = st.track_hk
    LEFT JOIN {{ ref('hub_key_signature') }} hks ON st.key_signature_id = hks.key_signature_id
    LEFT JOIN {{ ref('sat_key_signature') }} sks ON hks.key_signature_hk = sks.key_signature_hk
    LEFT JOIN {{ ref('hub_mode') }} hm ON st.mode_id = hm.mode_id
    LEFT JOIN {{ ref('sat_mode') }} sm ON hm.mode_hk = sm.mode_hk
),

track_artist AS (
    SELECT
        tb.*,
        sa.artist_name,
        sa.artist_mbid,
        sa.artist_familiarity,
        sa.artist_hotttnesss,
        sa.artist_latitude,
        sa.artist_longitude,
        sa.artist_location
    FROM track_base tb
    LEFT JOIN (
        SELECT 
            track_hk,
            artist_hk,
            ROW_NUMBER() OVER (PARTITION BY track_hk ORDER BY load_date ASC, artist_hk ASC) as rn
        FROM {{ ref('link_track_artist') }}
    ) lta ON tb.track_hk = lta.track_hk AND lta.rn = 1
    LEFT JOIN {{ ref('sat_artist') }} sa ON lta.artist_hk = sa.artist_hk
),

track_release AS (
    SELECT
        ta.*,
        sr.release,
        sr.release_7digitalid,
        sr.track_7digitalid
    FROM track_artist ta
    LEFT JOIN (
        SELECT 
            track_hk,
            release_hk,
            ROW_NUMBER() OVER (PARTITION BY track_hk ORDER BY load_date ASC, release_hk ASC) as rn
        FROM {{ ref('link_track_release') }}
    ) ltr ON ta.track_hk = ltr.track_hk AND ltr.rn = 1
    LEFT JOIN {{ ref('sat_release') }} sr ON ltr.release_hk = sr.release_hk
),

track_midi_match AS (
    SELECT
        tr.*,
        best_match.score as best_midi_match_score,
        hm.midi_md5 as best_midi_match_md5
    FROM track_release tr
    LEFT JOIN (
        SELECT 
            ltm.track_hk,
            ltm.midi_hk,
            sms.score,
            ROW_NUMBER() OVER (PARTITION BY ltm.track_hk ORDER BY sms.score DESC) as rn
        FROM {{ ref('link_track_midi') }} ltm
        JOIN {{ ref('sat_match_scores') }} sms ON ltm.link_track_midi_hk = sms.link_track_midi_hk
    ) best_match ON tr.track_hk = best_match.track_hk AND best_match.rn = 1
    LEFT JOIN {{ ref('hub_midi_file') }} hm ON best_match.midi_hk = hm.midi_hk
)

SELECT
    track_hk,
    track_id,
    
    -- Audio features for ML/analysis
    danceability,
    energy,
    key_name as key_signature,
    key_confidence,
    loudness,
    mode_name as mode,
    mode_confidence,
    tempo,
    time_signature,
    time_signature_confidence,
    duration,
    
    -- Track metadata
    title,
    genre,
    year,
    song_hotttnesss,
    
    -- Artist information
    artist_name,
    artist_mbid,
    artist_familiarity,
    artist_hotttnesss,
    artist_location,
    artist_latitude,
    artist_longitude,
    
    -- Release information
    release,
    release_7digitalid,
    track_7digitalid,
    
    -- MIDI matching
    best_midi_match_score,
    best_midi_match_md5,
    CASE 
        WHEN best_midi_match_score >= 0.8 THEN 'High'
        WHEN best_midi_match_score >= 0.6 THEN 'Medium'
        WHEN best_midi_match_score IS NOT NULL THEN 'Low'
        ELSE 'No Match'
    END as midi_match_quality,
    
    -- Time series summary statistics
    bars_count,
    beats_count,
    sections_count,
    segments_count,
    tatums_count,
    avg_bars_confidence,
    avg_beats_confidence,
    avg_segments_confidence,
    
    -- Technical metadata
    audio_md5,
    analysis_sample_rate,
    analyzer_version,
    song_id,
    end_of_fade_in,
    start_of_fade_out,
    
    current_timestamp as created_at

FROM (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY track_hk ORDER BY best_midi_match_score DESC NULLS LAST, track_id ASC) as final_rn
    FROM track_midi_match
) deduplicated
WHERE final_rn = 1
ORDER BY track_hk