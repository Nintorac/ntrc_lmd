WITH track_features AS (
    SELECT
        st.key_signature_id,
        st.mode_id,
        st.time_signature,
        sks.key_name,
        sm.mode_name,
        CASE 
            WHEN st.tempo < 60 THEN 'Very Slow (<60 BPM)'
            WHEN st.tempo < 90 THEN 'Slow (60-90 BPM)'
            WHEN st.tempo < 120 THEN 'Moderate (90-120 BPM)'
            WHEN st.tempo < 140 THEN 'Fast (120-140 BPM)'
            WHEN st.tempo < 180 THEN 'Very Fast (140-180 BPM)'
            ELSE 'Extreme (>180 BPM)'
        END as tempo_range,
        CASE 
            WHEN st.energy < 0.2 THEN 'Very Low Energy'
            WHEN st.energy < 0.4 THEN 'Low Energy'
            WHEN st.energy < 0.6 THEN 'Medium Energy'
            WHEN st.energy < 0.8 THEN 'High Energy'
            ELSE 'Very High Energy'
        END as energy_range,
        CASE 
            WHEN st.danceability < 0.2 THEN 'Very Low Danceability'
            WHEN st.danceability < 0.4 THEN 'Low Danceability'
            WHEN st.danceability < 0.6 THEN 'Medium Danceability'
            WHEN st.danceability < 0.8 THEN 'High Danceability'
            ELSE 'Very High Danceability'
        END as danceability_range,
        st.tempo,
        st.energy,
        st.danceability,
        st.loudness,
        st.duration,
        st.year,
        sa.artist_name
    FROM {{ ref('sat_track') }} st
    LEFT JOIN {{ ref('hub_track') }} ht ON st.track_hk = ht.track_hk
    LEFT JOIN {{ ref('link_track_artist') }} lta ON ht.track_hk = lta.track_hk
    LEFT JOIN {{ ref('sat_artist') }} sa ON lta.artist_hk = sa.artist_hk
    LEFT JOIN {{ ref('hub_key_signature') }} hks ON st.key_signature_id = hks.key_signature_id
    LEFT JOIN {{ ref('sat_key_signature') }} sks ON hks.key_signature_hk = sks.key_signature_hk
    LEFT JOIN {{ ref('hub_mode') }} hm ON st.mode_id = hm.mode_id
    LEFT JOIN {{ ref('sat_mode') }} sm ON hm.mode_hk = sm.mode_hk
    WHERE st.key_signature_id IS NOT NULL 
      AND st.mode_id IS NOT NULL 
      AND st.time_signature IS NOT NULL
),

key_analysis AS (
    SELECT
        'Key Distribution' as feature_category,
        CAST(key_signature_id AS VARCHAR) as feature_value,
        COUNT(*) as track_count,
        COUNT(DISTINCT artist_name) as artist_count,
        ROUND(AVG(tempo), 1) as avg_tempo,
        ROUND(AVG(energy), 3) as avg_energy,
        ROUND(AVG(danceability), 3) as avg_danceability,
        ROUND(AVG(loudness), 2) as avg_loudness,
        ROUND(AVG(duration), 1) as avg_duration,
        MIN(year) as earliest_year,
        MAX(year) as latest_year,
        key_name as comments
    FROM track_features
    GROUP BY key_signature_id, key_name
),

mode_analysis AS (
    SELECT
        'Mode Distribution' as feature_category,
        CAST(mode_id AS VARCHAR) as feature_value,
        COUNT(*) as track_count,
        COUNT(DISTINCT artist_name) as artist_count,
        ROUND(AVG(tempo), 1) as avg_tempo,
        ROUND(AVG(energy), 3) as avg_energy,
        ROUND(AVG(danceability), 3) as avg_danceability,
        ROUND(AVG(loudness), 2) as avg_loudness,
        ROUND(AVG(duration), 1) as avg_duration,
        MIN(year) as earliest_year,
        MAX(year) as latest_year,
        mode_name as comments
    FROM track_features
    GROUP BY mode_id, mode_name
),

time_signature_analysis AS (
    SELECT
        'Time Signature Distribution' as feature_category,
        CAST(time_signature AS VARCHAR) || '/4' as feature_value,
        COUNT(*) as track_count,
        COUNT(DISTINCT artist_name) as artist_count,
        ROUND(AVG(tempo), 1) as avg_tempo,
        ROUND(AVG(energy), 3) as avg_energy,
        ROUND(AVG(danceability), 3) as avg_danceability,
        ROUND(AVG(loudness), 2) as avg_loudness,
        ROUND(AVG(duration), 1) as avg_duration,
        MIN(year) as earliest_year,
        MAX(year) as latest_year,
        CAST(time_signature AS VARCHAR) || '/4 time' as comments
    FROM track_features
    GROUP BY time_signature
),

tempo_analysis AS (
    SELECT
        'Tempo Distribution' as feature_category,
        tempo_range as feature_value,
        COUNT(*) as track_count,
        COUNT(DISTINCT artist_name) as artist_count,
        ROUND(AVG(tempo), 1) as avg_tempo,
        ROUND(AVG(energy), 3) as avg_energy,
        ROUND(AVG(danceability), 3) as avg_danceability,
        ROUND(AVG(loudness), 2) as avg_loudness,
        ROUND(AVG(duration), 1) as avg_duration,
        MIN(year) as earliest_year,
        MAX(year) as latest_year,
        NULL as comments
    FROM track_features
    GROUP BY tempo_range
),

energy_analysis AS (
    SELECT
        'Energy Distribution' as feature_category,
        energy_range as feature_value,
        COUNT(*) as track_count,
        COUNT(DISTINCT artist_name) as artist_count,
        ROUND(AVG(tempo), 1) as avg_tempo,
        ROUND(AVG(energy), 3) as avg_energy,
        ROUND(AVG(danceability), 3) as avg_danceability,
        ROUND(AVG(loudness), 2) as avg_loudness,
        ROUND(AVG(duration), 1) as avg_duration,
        MIN(year) as earliest_year,
        MAX(year) as latest_year,
        NULL as comments
    FROM track_features
    GROUP BY energy_range
),

danceability_analysis AS (
    SELECT
        'Danceability Distribution' as feature_category,
        danceability_range as feature_value,
        COUNT(*) as track_count,
        COUNT(DISTINCT artist_name) as artist_count,
        ROUND(AVG(tempo), 1) as avg_tempo,
        ROUND(AVG(energy), 3) as avg_energy,
        ROUND(AVG(danceability), 3) as avg_danceability,
        ROUND(AVG(loudness), 2) as avg_loudness,
        ROUND(AVG(duration), 1) as avg_duration,
        MIN(year) as earliest_year,
        MAX(year) as latest_year,
        NULL as comments
    FROM track_features
    GROUP BY danceability_range
),

decade_analysis AS (
    SELECT
        'Decade Trends' as feature_category,
        CAST(FLOOR(year / 10) * 10 AS VARCHAR) || 's' as feature_value,
        COUNT(*) as track_count,
        COUNT(DISTINCT artist_name) as artist_count,
        ROUND(AVG(tempo), 1) as avg_tempo,
        ROUND(AVG(energy), 3) as avg_energy,
        ROUND(AVG(danceability), 3) as avg_danceability,
        ROUND(AVG(loudness), 2) as avg_loudness,
        ROUND(AVG(duration), 1) as avg_duration,
        MIN(year) as earliest_year,
        MAX(year) as latest_year,
        NULL as comments
    FROM track_features
    WHERE year IS NOT NULL AND year > 1900 AND year < 2100
    GROUP BY FLOOR(year / 10) * 10
),

combined_analysis AS (
    SELECT * FROM key_analysis
    UNION ALL
    SELECT * FROM mode_analysis
    UNION ALL
    SELECT * FROM time_signature_analysis
    UNION ALL
    SELECT * FROM tempo_analysis
    UNION ALL
    SELECT * FROM energy_analysis
    UNION ALL
    SELECT * FROM danceability_analysis
    UNION ALL
    SELECT * FROM decade_analysis
)

SELECT
    feature_category,
    feature_value,
    track_count,
    artist_count,
    ROUND(track_count * 100.0 / SUM(track_count) OVER (PARTITION BY feature_category), 2) as percentage_of_category,
    avg_tempo,
    avg_energy,
    avg_danceability,
    avg_loudness,
    avg_duration,
    earliest_year,
    latest_year,
    current_timestamp as created_at,
    comments
FROM combined_analysis
ORDER BY 
    feature_category,
    CASE feature_category
        WHEN 'Decade Trends' THEN CAST(REPLACE(feature_value, 's', '') AS INTEGER)
        ELSE track_count
    END DESC