{{ config(
        tags=['incremental'],
        options={
            'partition_by': 'partition_col',
            'OVERWRITE_OR_IGNORE': true
        }
    )
}}
SELECT
    t.track_hk,
    
    -- Audio analysis data
    h5.analysis.songs.audio_md5,
    h5.analysis.songs.analysis_sample_rate,
    h5.analysis.songs.danceability,
    h5.analysis.songs.duration,
    h5.analysis.songs.end_of_fade_in,
    h5.analysis.songs.energy,
    h5.analysis.songs.key,
    h5.analysis.songs.key_confidence,
    h5.analysis.songs.loudness,
    h5.analysis.songs.mode,
    h5.analysis.songs.mode_confidence,
    h5.analysis.songs.start_of_fade_out,
    h5.analysis.songs.tempo,
    h5.analysis.songs.time_signature,
    h5.analysis.songs.time_signature_confidence,
    
    -- Metadata
    h5.metadata.songs.title,
    h5.metadata.songs.genre,
    h5.musicbrainz.songs.year,
    h5.metadata.songs.analyzer_version,
    h5.metadata.songs.song_id,
    h5.metadata.songs.song_hotttnesss,
    
    -- Index references for time series data
    h5.analysis.songs.idx_bars_confidence,
    h5.analysis.songs.idx_bars_start,
    h5.analysis.songs.idx_beats_confidence,
    h5.analysis.songs.idx_beats_start,
    h5.analysis.songs.idx_sections_confidence,
    h5.analysis.songs.idx_sections_start,
    h5.analysis.songs.idx_segments_confidence,
    h5.analysis.songs.idx_segments_loudness_max,
    h5.analysis.songs.idx_segments_loudness_max_time,
    h5.analysis.songs.idx_segments_loudness_start,
    h5.analysis.songs.idx_segments_pitches,
    h5.analysis.songs.idx_segments_start,
    h5.analysis.songs.idx_segments_timbre,
    h5.analysis.songs.idx_tatums_confidence,
    h5.analysis.songs.idx_tatums_start,
    
    -- Time series arrays
    h5.analysis.bars_start,
    h5.analysis.bars_confidence,
    h5.analysis.beats_start,
    h5.analysis.beats_confidence,
    h5.analysis.sections_start,
    h5.analysis.sections_confidence,
    h5.analysis.segments_start,
    h5.analysis.segments_confidence,
    h5.analysis.segments_loudness_max,
    h5.analysis.segments_loudness_max_time,
    h5.analysis.segments_loudness_start,
    h5.analysis.segments_pitches,
    h5.analysis.segments_timbre,
    h5.analysis.tatums_start,
    h5.analysis.tatums_confidence,
    
    -- Audit fields
    current_timestamp as load_date,
    'lmd_h5' as record_source,
    
    -- Operational fields
    substring(track_hk, 1, 1) partition_col

FROM {{ ref('hub_track') }} t
JOIN {{ source('bronze_data', 'h5_extract') }} h5 ON t.track_id = h5.track_id
where partition_col='{{ var("partition_filter", "a") }}'
ORDER BY track_hk