# Quickstart Guide

This guide shows three different ways to work with the Lakh MIDI Dataset, depending on your needs and setup preferences.

## Option 1: Local Development with Cloned Data Repository

For users who want full local access to the dataset and plan to do extensive analysis.

### Prerequisites
- Git
- DuckDB CLI or Python with DuckDB

### Steps

1. **Clone the data repository:**
   ```bash
   git clone git@hf.co:datasets/nintorac/ntrc_lmd
   cd ntrc_lmd
   ```

2. **Connect to the local database:**
   ```bash
   # Using DuckDB CLI
   duckdb lakh_remote.duckdb
   ```
   
   Or in Python:
   ```python
   import duckdb
   
   # Connect to local DuckDB file
   conn = duckdb.connect('lakh_remote.duckdb')
   
   # Query the data
   result = conn.execute("""
       SELECT COUNT(*) as track_count 
       FROM sat_track
   """).fetchall()
   
   print(f"Total tracks: {result[0][0]}")
   ```

### Advantages
- ✅ Full offline access
- ✅ Fastest query performance
- ✅ Complete control over data versioning
- ✅ Can modify and extend the dataset

### Disadvantages
- ❌ Large download size (~2GB+)
- ❌ Requires local storage space
- ❌ Manual updates needed

## Option 2: Remote Access for Ad Hoc Queries

For users who want quick access without downloading the full dataset.

### Prerequisites
- Internet connection
- DuckDB CLI, Python with DuckDB, or a database IDE

### Using Python or Jupyter

1. **Query remotely using SQL magic (in Jupyter):**
   ```python
   %load_ext sql
   %sql duckdb:///:memory:
   
   # Attach remote database
   %%sql
   ATTACH 'hf://datasets/nintorac/ntrc_lakh_midi/lakh_remote.duckdb' AS lakh_remote;
   
   # Sample the artist profile mart table
   %%sql
   CREATE TABLE my_artist_sample AS 
   SELECT * FROM lakh_remote.mart_artist_profile 
   WHERE artist_profile_tier = 'High Profile' 
   LIMIT 100;
   
   # Query the sample
   %%sql
   SELECT 
       artist_name,
       total_tracks,
       avg_tempo,
       most_common_key,
       top_terms[1:3] as top_3_terms
   FROM my_artist_sample
   ORDER BY total_tracks DESC;
   ```

2. **Or use Python directly:**
   ```python
   import duckdb
   
   conn = duckdb.connect(':memory:')
   conn.execute("ATTACH 'hf://datasets/nintorac/ntrc_lakh_midi/lakh_remote.duckdb' AS lakh_remote")
   
   # Create local sample from gold layer (recommended pattern)
   conn.execute("""
       CREATE TABLE my_artist_sample AS 
       SELECT * FROM lakh_remote.mart_artist_profile 
       WHERE artist_profile_tier = 'High Profile' 
       LIMIT 100
   """)
   
   # Query the sample
   df = conn.execute("""
       SELECT 
           artist_name,
           total_tracks,
           avg_tempo,
           most_common_key,
           top_terms[1:3] as top_3_terms
       FROM my_artist_sample
       ORDER BY total_tracks DESC
   """).df()
   
   print(df.head())
   ```


```{tip}
Start with the `mart_*` tables for easy to understand and interesting data. The pattern of creating a local table first (as shown above) is recommended because remote queries can be slow.
```

### Advantages
- ✅ No local storage required
- ✅ Always up-to-date
- ✅ Quick setup
- ✅ Good for exploration and prototyping

### Disadvantages
- ❌ Requires internet connection
- ❌ Extremely slow query performance
- ❌ Limited by network bandwidth (not good for high density columns eg midi file content, midi track analysis columns)
- ❌ No offline access

## Option 3: Hybrid Approach - Export Subset to Local DuckDB

For users who want to work with a subset of data locally after initial remote exploration.

### Prerequisites
- DuckDB (CLI, Python, or database IDE)
- Initial internet connection

### Using Python

1. **Connect to remote and export subset:**
   ```python
   import duckdb
   
   # Connect to memory database first
   conn = duckdb.connect(':memory:')
   
   # Attach remote database
   conn.execute("ATTACH 'hf://datasets/nintorac/ntrc_lakh_midi/lakh_remote.duckdb' AS lakh_remote")
   
   # Create local database file
   conn.execute("ATTACH 'my_local_lakh.duckdb' AS local_db")
   
   # Export artist profile data (start with gold layer)
   conn.execute("""
       CREATE TABLE local_db.artist_profiles AS 
       SELECT * FROM lakh_remote.mart_artist_profile 
       WHERE artist_profile_tier = 'High Profile'
   """)
   
   # Export track analytics
   conn.execute("""
       CREATE TABLE local_db.track_analytics AS 
       SELECT * FROM lakh_remote.mart_track_analytics
       WHERE year >= 2000
   """)
   
   # Close and reconnect to local file
   conn.close()
   ```

2. **Work with local exported data:**
   ```python
   # Connect directly to local database
   local_conn = duckdb.connect('my_local_lakh.duckdb')
   
   # Now query locally
   result = local_conn.execute("""
       SELECT 
           artist_name,
           total_tracks,
           avg_tempo,
           most_common_key
       FROM artist_profiles
       ORDER BY total_tracks DESC
       LIMIT 10
   """).df()
   
   print(result)
   ```


3. **Advanced: Export with joins and transformations:**
   ```python
   conn = duckdb.connect(':memory:')
   conn.execute("ATTACH 'hf://datasets/nintorac/ntrc_lakh_midi/lakh_remote.duckdb' AS remote")
   conn.execute("ATTACH 'my_analysis.duckdb' AS local")
   
   # Create enriched dataset for analysis using silver layer
   conn.execute("""
       CREATE TABLE local.analysis_dataset AS
       SELECT 
           t.track_hk,
           t.title,
           t.year,
           t.tempo,
           t.energy,
           t.danceability,
           t.loudness,
           m.file_size,
           m.num_tracks as midi_track_count
       FROM remote.sat_track t
       JOIN remote.sat_midi_file m ON t.track_hk = m.track_hk
       WHERE t.year IS NOT NULL 
       AND t.tempo IS NOT NULL
   """)
   ```

### Advantages
- ✅ Best of both worlds: remote exploration + local performance
- ✅ Control over dataset size
- ✅ Fast local queries after export
- ✅ Can work offline after initial setup
- ✅ Customizable data subsets

### Disadvantages
- ❌ Requires initial setup step
- ❌ Manual updates needed for new data
- ❌ Still uses local storage (but configurable)

## Using Database IDEs (DBeaver, Beekeeper Studio)

Database IDEs provide a user-friendly graphical interface for working with the Lakh MIDI dataset. The recommended workflow is to create a local or in-memory DuckDB instance and attach to the remote database.

### Setup Steps

1. **Create a new DuckDB connection** in your IDE:
   - **Connection type:** DuckDB
   - **Database file:** Choose either:
     - `:memory:` for temporary in-memory database
     - `my_local_lakh.duckdb` for persistent local file

2. **Attach to the remote database:**
   ```sql
   ATTACH 'hf://datasets/nintorac/ntrc_lakh_midi/lakh_remote.duckdb' AS lakh_remote;
   ```

### Basic Querying

```sql
-- Sample the artist profile mart table (recommended pattern)
CREATE TABLE my_artist_sample AS 
SELECT * FROM lakh_remote.mart_artist_profile 
WHERE artist_profile_tier = 'High Profile' 
LIMIT 100;

-- Query the local sample
SELECT 
    artist_name,
    total_tracks,
    avg_tempo,
    most_common_key,
    top_terms[1:3] as top_3_terms
FROM my_artist_sample
ORDER BY total_tracks DESC;
```

### Data Export

To export subsets for local analysis:

```sql
-- Export artist profiles
CREATE TABLE artist_profiles AS 
SELECT * FROM lakh_remote.mart_artist_profile 
WHERE artist_profile_tier = 'High Profile';

-- Export track analytics
CREATE TABLE track_analytics AS 
SELECT * FROM lakh_remote.mart_track_analytics
WHERE year >= 2000;

-- Advanced: Join data from silver layer
CREATE TABLE analysis_dataset AS
SELECT 
    t.track_hk,
    t.title,
    t.year,
    t.tempo,
    t.energy,
    t.danceability,
    t.loudness,
    m.file_size,
    m.num_tracks as midi_track_count
FROM lakh_remote.sat_track t
JOIN lakh_remote.sat_midi_file m ON t.track_hk = m.track_hk
WHERE t.year IS NOT NULL 
AND t.tempo IS NOT NULL
LIMIT 10000; -- Be careful with large joins
```

### Tips for IDE Usage

- **Start with gold layer tables** (`mart_*`) for easier exploration
- **Create local tables first** before complex analysis to improve performance
- **Use LIMIT clauses** when exploring large tables to avoid long wait times
- **Save your connection settings** with the ATTACH command for reuse
- **Export wizards** in most IDEs can help with data subset exports

```{tip}
Always create local tables from remote queries before doing analysis. Direct queries to the remote database can be extremely slow.
```

## Choosing the Right Approach

| Use Case | Recommended Option |
|----------|-------------------|
| Data science research, extensive analysis | Option 1: Local clone |
| Quick exploration, prototyping | Option 2: Remote access |
| Production analysis on subset | Option 3: Hybrid export |
| Jupyter notebook tutorials | Option 2: Remote access |
| Offline analysis required | Option 1 or 3 |
| Storage constraints | Option 2: Remote access |
| Need latest data always | Option 2: Remote access |

## Next Steps

After choosing your setup approach:

1. **Explore the data structure**: Check out the [data discovery notebooks](discovery/silver/silver.md)
2. **Learn about features**: Read the [Echonest Features Guide](echonest_features_guide.md) 
3. **See examples**: Browse the [examples directory](examples/) for common analysis patterns
4. **Check the API**: Review the full Python API documentation

## Common Issues and Solutions

### Large Query Performance
For better performance with large queries:
```python
# Use LIMIT for initial exploration
conn.execute("SELECT * FROM lakh_remote.sat_track LIMIT 1000")

# Subset columns to only what you will need
conn.execute("""
SELECT 
   track_hk, 
   title,
   genre,
   year,
   -- Skip high density columns 
   --bars_start,
   --bars_confidence,
   --beats_start,
   --beats_confidence,
FROM lakh_remote.sat_track
""")
```

### Memory Issues
If running out of memory:
```python
# Stream results instead of loading all at once
for batch in conn.execute("SELECT * FROM table").fetch_df_chunk(10000):
    process_batch(batch)

# Make use of parameter pushdown to reduce table size
conn.execute("SELECT * FROM table where track_hk=''").fetch_df_chunk(10000)
```
