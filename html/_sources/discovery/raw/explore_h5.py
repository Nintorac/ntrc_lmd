# %% [markdown]
"""
# LMD Matched H5

Quick look into `lmd_matched_h5.tar.gz`
"""

# %%
from tempfile import NamedTemporaryFile, TemporaryDirectory
import warnings
warnings.filterwarnings('ignore')

import tarfile
import h5py
import numpy as np
import os
import pandas as pd

from lakh_midi_dataset import project_dir

# %% [markdown]
"""
## Archive Contents

First, let's see what's in the tar.gz file
"""

# %%
tar_path = project_dir / "lmd_matched_h5.tar.gz"
print(f"Opening {tar_path}...")

with tarfile.open(tar_path, 'r|gz') as tar:
    members = tar.getmembers()
    print(f"Found {len(members)} files in the archive")

# %% [markdown]
"""
## File Listing

Let's look at the first few files
"""

# %%
print("First 10 files:")
for i, member in enumerate(members[:10]):
    print(f"  {member.name} ({member.size} bytes)")

# %% [markdown]
"""
## File Types

Count different file types in the archive
"""

# %%
extensions = {}
for member in members:
    if member.isfile():
        ext = os.path.splitext(member.name)[1]
        extensions[ext] = extensions.get(ext, 0) + 1

print("File types found:")
for ext, count in sorted(extensions.items()):
    print(f"  {ext}: {count} files")

# %% [markdown]
"""
## H5 File Structure

Let's extract and examine the first H5 file
"""

# %%
h5_files = [m for m in members if m.name.endswith('.h5')]
print(f"\nFound {len(h5_files)} H5 files")

tf = TemporaryDirectory()

if h5_files:
    first_h5 = h5_files[0]
    print(f"Examining: {first_h5.name}")
    
    # Extract it temporarily
    with tarfile.open(tar_path, 'r|gz') as tar:
        tar.extract(first_h5, path=tf.name)
    
    h5_temp_path = f'{tf.name}/{first_h5.name}'

# %% [markdown]
"""
## H5 File Contents

Open the H5 file and see what's inside
"""

# %%
with h5py.File(h5_temp_path, 'r') as f:
    print("Keys in the H5 file:")
    for key in f.keys():
        print(f"  {key}: {type(f[key])}")

# %% [markdown]
"""
## Dataset Details

Let's explore each dataset/group in detail
"""

# %%
with h5py.File(h5_temp_path, 'r') as f:
    for key in f.keys():
        item = f[key]
        print(f"\n--- {key} ---")
        
        if isinstance(item, h5py.Dataset):
            print(f"Dataset shape: {item.shape}")
            print(f"Data type: {item.dtype}")
            if item.size < 100:  # Only show small datasets
                print(f"Data: {item[...]}")
            else:
                print(f"First few values: {item.flat[:10]}")
        
        elif isinstance(item, h5py.Group):
            print(f"Group with {len(item)} items:")
            for subkey in item.keys():
                subitem = item[subkey]
                if isinstance(subitem, h5py.Dataset):
                    print(f"  {subkey}: dataset {subitem.shape} {subitem.dtype}")
                else:
                    print(f"  {subkey}: {type(subitem)}")

# %% [markdown]
"""
## Multiple File Analysis

Let's check a few more H5 files to see if they have similar structure
"""

# %%
print("Checking structure of first 3 H5 files...")

with tarfile.open(tar_path, 'r|gz') as tar:
    for i, h5_file in enumerate(h5_files[:3]):
        print(f"\n=== File {i+1}: {h5_file.name} ===")
        
        tar.extract(h5_file, path="/tmp/")
        temp_path = f"/tmp/{h5_file.name}"
        
        try:
            with h5py.File(temp_path, 'r') as f:
                print(f"Keys: {list(f.keys())}")
                for key in f.keys():
                    if isinstance(f[key], h5py.Dataset):
                        print(f"  {key}: {f[key].shape} {f[key].dtype}")
        except Exception as e:
            print(f"Error reading file: {e}")
        finally:
            if os.path.exists(temp_path):
                os.remove(temp_path)

# %% [markdown]
"""
## Songs Data Extraction

Extract songs data from analysis, metadata, and musicbrainz groups for first 10 files
"""

# %%
print("Extracting songs data from first 10 H5 files...")

analysis_songs = []
metadata_songs = []
musicbrainz_songs = []

with tarfile.open(tar_path, 'r|gz') as tar:
    for i, h5_file in enumerate(h5_files[:10]):
        print(f"Processing file {i+1}: {h5_file.name}")
        
        tar.extract(h5_file, path="/tmp/")
        temp_path = f"/tmp/{h5_file.name}"
        
        try:
            with h5py.File(temp_path, 'r') as f:
                # Extract analysis/songs
                if 'analysis' in f and 'songs' in f['analysis']:
                    songs_data = f['analysis']['songs'][...]
                    df = pd.DataFrame(songs_data)
                    df['filename'] = h5_file.name
                    analysis_songs.append(df)
                
                # Extract metadata/songs  
                if 'metadata' in f and 'songs' in f['metadata']:
                    songs_data = f['metadata']['songs'][...]
                    df = pd.DataFrame(songs_data)
                    df['filename'] = h5_file.name
                    metadata_songs.append(df)
                
                # Extract musicbrainz/songs
                if 'musicbrainz' in f and 'songs' in f['musicbrainz']:
                    songs_data = f['musicbrainz']['songs'][...]
                    df = pd.DataFrame(songs_data)
                    df['filename'] = h5_file.name
                    musicbrainz_songs.append(df)
                    
        except Exception as e:
            print(f"Error processing {h5_file.name}: {e}")
        finally:
            if os.path.exists(temp_path):
                os.remove(temp_path)

# %% [markdown]
"""
## Data Summary

Combine all DataFrames and show summary statistics
"""

# %%
if analysis_songs:
    analysis_df = pd.concat(analysis_songs, ignore_index=True)
    print(f"\nAnalysis songs DataFrame shape: {analysis_df.shape}")
    print("Analysis columns:", list(analysis_df.columns))
else:
    analysis_df = pd.DataFrame()

#%%
analysis_df.head()

#%%
if metadata_songs:
    metadata_df = pd.concat(metadata_songs, ignore_index=True)
    print(f"\nMetadata songs DataFrame shape: {metadata_df.shape}")
    print("Metadata columns:", list(metadata_df.columns))
else:
    metadata_df = pd.DataFrame()

#%%
metadata_df.head()

#%%
if musicbrainz_songs:
    musicbrainz_df = pd.concat(musicbrainz_songs, ignore_index=True)
    print(f"\nMusicbrainz songs DataFrame shape: {musicbrainz_df.shape}")
    print("Musicbrainz columns:", list(musicbrainz_df.columns))
else:
    musicbrainz_df = pd.DataFrame()

#%%
musicbrainz_df.head()

# %%
