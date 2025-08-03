WITH lmd_full_files AS (
    SELECT DISTINCT
        midi_md5,
        'lmd_full' as record_source
    FROM {{ source('bronze_data', 'raw_midi_files') }}
    WHERE midi_md5 IS NOT NULL
),

match_score_files AS (
    SELECT DISTINCT
        midi_md5,
        'match_scores' as record_source
    FROM {{ source('bronze_data', 'raw_match_scores') }}
    WHERE midi_md5 IS NOT NULL
    AND midi_md5 NOT IN (SELECT midi_md5 FROM lmd_full_files)
),

md5_path_files AS (
    SELECT DISTINCT
        midi_md5,
        'md5_paths' as record_source
    FROM {{ source('bronze_data', 'raw_md5_paths') }}
    WHERE midi_md5 IS NOT NULL
    AND midi_md5 NOT IN (SELECT midi_md5 FROM lmd_full_files)
    AND midi_md5 NOT IN (SELECT midi_md5 FROM match_score_files)
),

midi_sources AS (
    SELECT * FROM lmd_full_files
    UNION ALL
    SELECT * FROM match_score_files
    UNION ALL
    SELECT * FROM md5_path_files
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['midi_md5']) }} as midi_hk,
    midi_md5,
    current_timestamp as load_date,
    record_source
FROM midi_sources