# Lakh MIDI Dataset Pipeline

A comprehensive data pipeline that transforms the Lakh MIDI Dataset from raw files into a structured Data Vault 2.0 model using modern data engineering practices.

## What This Is

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

## Key Features

- **Data Vault 2.0 modeling** for scalability and auditability
- **Comprehensive testing** with referential integrity checks
- **Partitioned processing** for handling large datasets efficiently

```{tableofcontents}
```
