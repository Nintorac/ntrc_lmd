# %% [markdown]
"""
# 🎵 MIDI Tokenization Demo

This notebook demonstrates how to:
1. Connect to the NTRC Lakh MIDI dataset 
2. Query random MIDI files from the database
3. Tokenize MIDI files using the `symbolic-music` library

Based on the symbolic_example.md and ntrc_dataset.md documentation.
"""

# %%
import duckdb
import pandas as pd
from pathlib import Path
import tempfile
from symbolic_music.aria import MidiDict, AbsTokenizer, normalize_midi_dict
from tqdm.notebook import tqdm
import warnings
warnings.filterwarnings('ignore')

# %% [markdown]
"""
## Step 1: Connect to the Remote NTRC Lakh MIDI Database

We'll attach to the remote database hosted on Hugging Face and query
the MIDI files with their metadata.
"""
# %%
# Initialize DuckDB connection
conn = duckdb.connect()

# Attach the remote database
print("📡 Connecting to remote NTRC Lakh MIDI database...")
conn.execute("ATTACH 'hf://datasets/nintorac/ntrc_lakh_midi/lakh_remote.duckdb' AS lakh_remote;")
print("✅ Connected successfully!")

# %% [markdown]
"""
## Step 2: Explore the Available Tables

Let's see what tables are available in the remote database.
"""
# %%
# List all tables in the remote database
tables_query = """
SHOW ALL TABLES
"""

tables_df = conn.execute(tables_query).df()
print("🗂️  Available tables in the database:")
print(tables_df.to_string(index=False))

# %% [markdown]
"""
## Step 3: Query Random MIDI Files with Metadata

We'll query a bunch of midis for which we have matched metadata including
artist info, tempo, key signature, etc.
"""

#%%
print("\n🎲 Querying 50 random MIDI files...")

# Query to get random MIDI files with rich metadata
midi_query = """
WITH random_midis AS (
    SELECT 
        mf.midi_md5,
        mf.midi_hk,
        smf.file_content,
        smf.file_size,
        -- Artist info
        sa.artist_name,
        sa.artist_location,
        sa.artist_familiarity,
        sa.artist_hotttnesss,
        -- Track info  
        st.title,
        st.year,
        st.tempo
    FROM (from lakh_remote.hub_midi_file limit 500) mf
    INNER JOIN lakh_remote.sat_midi_file smf ON mf.midi_hk = smf.midi_hk
    -- Join to tracks via link table
    LEFT JOIN lakh_remote.link_track_midi ltm ON mf.midi_hk = ltm.midi_hk  
    LEFT JOIN lakh_remote.hub_track ht ON ltm.track_hk = ht.track_hk
    LEFT JOIN lakh_remote.sat_track st ON ht.track_hk = st.track_hk
    -- Join to artists via link table
    LEFT JOIN lakh_remote.link_track_artist lta ON ht.track_hk = lta.track_hk
    LEFT JOIN lakh_remote.hub_artist ha ON lta.artist_hk = ha.artist_hk  
    LEFT JOIN lakh_remote.sat_artist sa ON ha.artist_hk = sa.artist_hk
    WHERE smf.file_content IS NOT NULL
    AND smf.file_size > 1000  -- Filter out very small files
    qualify row_number() over (partition by mf.midi_hk)=1
)
SELECT * FROM random_midis
where artist_name is not null;
"""

midi_df = conn.execute(midi_query).df()
print(f"✅ Retrieved {len(midi_df)} MIDI files")
print(f"📊 Total file size: {midi_df['file_size'].sum() / 1024 / 1024:.1f} MB")

# %% [markdown]
"""
## Step 4: Display Sample of Retrieved Data

Let's look at what we got - showing key metadata for our MIDI files.
"""

#%%
# Display sample of the data
print("\n📋 Sample of retrieved MIDI files:")
sample_cols = ['midi_md5', 'artist_name', 'title', 'year', 'tempo', 'file_size']

display_df = midi_df[sample_cols].head(10)
pd.set_option('display.max_columns', None)
pd.set_option('display.width', None)
print(display_df.to_string(index=False))

# %% [markdown]
"""
## Step 5: Initialize the ARIA AbsTokenizer

Following the symbolic_example.md documentation to set up tokenization.
"""

#%%
print("\n🎼 Initializing ARIA AbsTokenizer...")

# Initialize the tokenizer
tokenizer = AbsTokenizer()

print(f"✅ Tokenizer initialized with config:")
print(f"   - Time step: {tokenizer.time_step_ms}ms")
print(f"   - Max duration: {tokenizer.max_dur_ms}ms") 
# print(f"   - Vocabulary size: {len(tokenizer.vocab)}")

# %% [markdown]
"""
## Step 6: Process and Tokenize MIDI Files

Now we'll process each MIDI file:
1. Load MIDI data from bytes
2. Normalize the MIDI data 
3. Tokenize into sequence
4. Store results
"""

#%%
print("\n🔄 Processing and tokenizing MIDI files...")

# Storage for results
tokenization_results = []
successful_tokenizations = 0
failed_tokenizations = 0
err_out = ''

# Process each MIDI file
for idx, row in tqdm(midi_df.iterrows()):
    try:
        # Create temporary file from bytes
        with tempfile.NamedTemporaryFile(suffix='.mid', delete=False) as tmp_file:
            tmp_file.write(row['file_content'])
            tmp_path = tmp_file.name
        
        # Load MIDI file
        midi_dict = MidiDict.from_midi(tmp_path)
        
        # Normalize MIDI data (recommended preprocessing step)
        normalized_midi_dict = normalize_midi_dict(
            midi_dict=midi_dict,
            ignore_instruments=tokenizer.config["ignore_instruments"],
            instrument_programs=tokenizer.config["instrument_programs"], 
            time_step_ms=tokenizer.time_step_ms,
            max_duration_ms=tokenizer.max_dur_ms,
            drum_velocity=tokenizer.config["drum_velocity"],
            quantize_velocity_fn=tokenizer._quantize_velocity,
        )
        
        # Tokenize MIDI data to sequence
        sequence = tokenizer.tokenize(normalized_midi_dict, remove_preceding_silence=False)
        
        # Store results
        result = {
            'midi_md5': row['midi_md5'],
            'artist_name': row['artist_name'],
            'title': row['title'], 
            'tempo': row['tempo'],
            'file_size': row['file_size'],
            'sequence_length': len(sequence),
            'unique_tokens': len(set(sequence)),
            'sequence': sequence[:100],  # Store first 100 tokens as sample
        }
        
        tokenization_results.append(result)
        successful_tokenizations += 1
        
        # Clean up temp file
        Path(tmp_path).unlink()
        
    except Exception as e:
        failed_tokenizations += 1
        err_out += (f"   ❌ Failed to process {row['midi_md5']}: {str(e)[:100]}...\n")
        # Clean up temp file if it exists
        try:
            Path(tmp_path).unlink()
        except:
            pass
        continue

print(f"\n✅ Tokenization complete!")
print(f"   Successfully processed: {successful_tokenizations}")
print(f"   Failed to process: {failed_tokenizations}")
print(f"Errors:\n {err_out}")

# %% [markdown]
"""
## Step 7: Analyze Tokenization Results

Let's examine the tokenized sequences and their characteristics.
"""

#%%
if tokenization_results:
    results_df = pd.DataFrame(tokenization_results)
    
    print("\n📊 Tokenization Results Summary:")
    print("=" * 40)
    print(f"Total sequences: {len(results_df)}")
    print(f"Average sequence length: {results_df['sequence_length'].mean():.1f}")
    print(f"Median sequence length: {results_df['sequence_length'].median():.1f}")
    print(f"Min sequence length: {results_df['sequence_length'].min()}")
    print(f"Max sequence length: {results_df['sequence_length'].max()}")
    print(f"Average unique tokens per sequence: {results_df['unique_tokens'].mean():.1f}")
    
    print("\n🎵 Sample tokenized sequences:")
    print("=" * 40)
    
    # Show a few example tokenizations
    for i in range(min(3, len(results_df))):
        row = results_df.iloc[i]
        print(f"\n🎤 {row['artist_name']} - {row['title']}")
        print(f"   Sequence length: {row['sequence_length']}, Unique tokens: {row['unique_tokens']}")
        print(f"   First 20 tokens: {row['sequence'][:20]}")
        
    # Distribution of sequence lengths
    print(f"\n📈 Sequence Length Distribution:")
    length_bins = pd.cut(results_df['sequence_length'], bins=5, precision=0)
    length_dist = length_bins.value_counts().sort_index()
    for bin_range, count in length_dist.items():
        print(f"   {bin_range}: {count} sequences")

# %% [markdown]
"""
## Step 8: Vocabulary Analysis

Let's examine the tokenizer vocabulary and token usage.
"""

#%%

# Analyze token usage across all sequences
if tokenization_results:
    all_tokens = []
    for result in tokenization_results:
        all_tokens.extend(result['sequence'])
    
    unique_used_tokens = len(set(all_tokens))
    total_tokens = len(all_tokens)
    
    print(f"Total tokens generated: {total_tokens}")
    print(f"Unique tokens used: {unique_used_tokens}")  
    
    # Most common tokens
    from collections import Counter
    token_counts = Counter(all_tokens)
    print(f"\n🔥 Most common tokens:")
    for token, count in token_counts.most_common(10):
        # Convert token ID back to string if possible
        print(f"   {token}: {count} times")

# %% [markdown]
"""
## Step 9: Export Results for Further Analysis

Save our results to CSV for further analysis.
"""

#%%
if tokenization_results:
    # Create a summary dataset without the full sequences (too large)
    export_df = results_df.drop('sequence', axis=1).copy()
    
    # Add some computed features
    export_df['tokens_per_second'] = export_df['sequence_length'] / (export_df['file_size'] / 1000)  # rough estimate
    export_df['vocabulary_diversity'] = export_df['unique_tokens'] / export_df['sequence_length']
    
#%% [markdown]
"""
📈 Final Statistics:
"""
#%%
export_df.describe()

# %% [markdown]
"""
## Demo Complete! 🎉

We successfully:\
✅ Connected to the NTRC Lakh MIDI database\
✅ Queried a sample of random MIDI files with metadata  \
✅ Tokenized the MIDI files using the ARIA AbsTokenizer\
✅ Analyzed the tokenization results\
✅ Exported results for further analysis\

\
The tokenized sequences can now be used for:
- Music generation models
- Music analysis and classification  
- Sequence modeling experiments
- Musical pattern recognition
\
\
Next steps could include:
- Training a transformer model on the sequences
- Analyzing musical patterns in the tokens
- Comparing tokenization across different musical styles
- Fine-tuning generation models
"""
#%%
print("\n🎵✨ MIDI Tokenization Demo Complete! ✨🎵")

# Close database connection
conn.close()

# %%
