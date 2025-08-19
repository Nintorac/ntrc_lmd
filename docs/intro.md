# NTRC LMD

A distribution of Colin Raffel's Lakh Midi Datast using modern data tooling and designed to accelerate getting started working with this dataset. Find the data at [huggingface.co:datasets/nintorac/ntrc_lmd_data](https://huggingface.co/datasets/nintorac/ntrc_lmd_data)

## What Is This?

This project processes 176,581 unique MIDI files and their associated metadata from the [Lakh MIDI Dataset](https://colinraffel.com/projects/lmd/), transforming them into a clean, structured format suitable for music information retrieval research and machine learning applications.

The pipeline extracts and models:
- **MIDI Files** - Raw MIDI content and metadata  
- **Audio Analysis** - Echo Nest features (tempo, key, energy, etc.)
- **Artist Information** - Metadata, terms, and MusicBrainz tags
- **Track Relationships** - Track-to-MIDI matching scores and similarities

## Architecture Overview

The pipeline follows a **Bronze → Silver → Gold** medallion architecture:

- **Bronze Layer**: Raw extracted data from tar.gz and h5 files
- **Silver Layer**: Structured Data Vault 2.0 model with hubs, links, and satellites  
- **Gold Layer**: Denormalized marts optimized for analytics and ML

Prebuilt data is available for the silver layer as parquet files, there is also a DuckDB file that can provides views of the gold layer

## Key Features

- **Data Vault 2.0 modeling** for scalability and auditability
- **Comprehensive testing** with referential integrity checks
- **Partitioned processing** for handling large datasets efficiently

## Contributions

Contributions are very welcome, for now most of the documentation is LLM written, I would prefer to change that and contribtions welcome there.

If you use this dataset distribution and produce any interesting Gold layer queries I would be very happy to include them! Finally, if you do any interesting analysis that uses the dataset it would be great to include!

Go to (github.com:Nintorac/ntrc_lmd)[https://github.com/Nintorac/ntrc_lmd] to submit a PR.

```{tableofcontents}
```
