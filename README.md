# Lakh MIDI Dataset Pipeline

A comprehensive data pipeline to transform the Lakh MIDI Dataset from raw `tar.gz` and `h5` files into a structured Data Vault 2.0 model using dbt, dlt, DuckDB, and Parquet files.

## Overview

This project processes the Million Song Dataset's MIDI subset, extracting and modeling:
- **MIDI Files** - Raw MIDI file content and metadata
- **Audio Analysis** - Echo Nest audio features (tempo, key, energy, etc.)
- **Artist Information** - Artist metadata, terms, and MusicBrainz tags
- **Track Relationships** - Track-to-MIDI matching scores and similarities

## Architecture

### Bronze Layer (Raw Data)
- **`raw_midi_files`** - MIDI files extracted from `lmd_full.tar.gz`
- **`h5_extract`** - Musicbrainz and audio analysis data from `lmd_matched_h5.tar.gz`
- **`raw_match_scores`** - Track-to-MIDI matching scores from `match_scores.json`
- **`raw_md5_paths`** - MD5-to-path mappings from `md5_to_paths.json`

### Silver Layer (Data Vault 2.0)
Structured using Data Vault methodology with hubs, links, and satellites:

#### Hubs (Business Entities)
- **`hub_track`** - MusicBrainz tracks
- **`hub_artist`** - Artists (including similar artists from arrays)
- **`hub_release`** - 7digital releases  
- **`hub_midi_file`** - MIDI files by MD5 hash
- **`hub_midi_source`** - Source file paths

#### Links (Relationships)
- **`link_track_midi`** - Track-to-MIDI matches
- **`link_track_artist`** - Track-to-artist relationships
- **`link_track_release`** - Track-to-release relationships
- **`link_artist_similar`** - Artist similarity relationships
- **`link_midi_source`** - MIDI-to-source path mappings

#### Satellites (Descriptive Data)
- **`sat_track`** - Track details, audio analysis, and time-series arrays
- **`sat_artist`** - Artist metadata and location info
- **`sat_release`** - Release information
- **`sat_midi_file`** - MIDI file content and size
- **`sat_match_scores`** - Match quality scores
- **`sat_artist_similarity`** - Similarity rankings
- **`sat_artist_terms`** - Echo Nest artist terms (multi-active)
- **`sat_artist_mbtags`** - MusicBrainz tags (multi-active)

## Data Quality Features

### Deduplication Strategy
When artists appear in multiple tracks with similar metadata arrays, we consistently take the first occurrence ordered by `track_id` to ensure:
- No duplicate relationships
- Consistent ranking preservation
- Deterministic results

### Comprehensive Testing
- **Hub uniqueness** - Business keys are unique across all hubs
- **Referential integrity** - All foreign keys reference valid parents
- **Data quality** - Non-null constraints and accepted value validations
- **Composite keys** - Multi-active satellites have unique combinations
- **Custom tests** - Similarity ranking consistency validation

## Technology Stack

- **dlt** - Data extraction from unstructured files into parquet
- **dbt** - Data transformation and testing framework
- **DuckDB** - Analytics database engine
- **Parquet** - Columnar storage format
- **Python** - Data extraction and processing

## Usage

1. **Build bronze layer**: Load raw Parquet files as dbt sources `python bronze_pipeline.py`
2. **Build silver layer**: Transform to Data Vault structure with `dbt run`
3. **Run tests**: Validate data quality with `dbt test`

## Key Design Decisions

- **Data Vault 2.0** for flexibility and auditability
- **Source prioritization** when same entities appear in multiple sources
- **Array-based ranking** preservation from original data ordering
- **Comprehensive documentation** for all models and transformations