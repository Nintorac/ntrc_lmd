# %%
import tarfile
import os
import numpy as np
import pandas as pd

# %%
# First, let's see what's in the lmd_full tar.gz file
tar_path = "lmd_full.tar.gz"
print(f"Opening {tar_path}...")

with tarfile.open(tar_path, 'r:gz') as tar:
    members = tar.getmembers()
    print(f"Found {len(members)} files in the archive")

# %%
# Let's look at the first few files
print("First 10 files:")
for i, member in enumerate(members[:10]):
    print(f"  {member.name} ({member.size} bytes)")

# %%
# Count different file types
extensions = {}
for member in members:
    if member.isfile():
        ext = os.path.splitext(member.name)[1]
        extensions[ext] = extensions.get(ext, 0) + 1

print("File types found:")
for ext, count in sorted(extensions.items()):
    print(f"  {ext}: {count} files")

# %%
# Let's examine the structure of the first few MIDI files
midi_files = [m for m in members if m.name.endswith('.mid') or m.name.endswith('.midi')]
print(f"\nFound {len(midi_files)} MIDI files")

if midi_files:
    print("First 10 MIDI files:")
    for i, midi_file in enumerate(midi_files[:10]):
        print(f"  {midi_file.name} ({midi_file.size} bytes)")

# %%
# Let's also check the directory structure
directories = set()
for member in members:
    if member.isfile():
        dir_path = os.path.dirname(member.name)
        if dir_path:
            directories.add(dir_path)

print(f"\nFound {len(directories)} unique directories")
print("First 20 directories:")
for i, directory in enumerate(sorted(directories)[:20]):
    print(f"  {directory}")

# %%
# Check if specific MIDI file exists in the archive
target_file = "6cf66679024e795a213d9465b1e380d5.mid"
print(f"Searching for {target_file} in the archive...")

found_file = None
with tarfile.open(tar_path, 'r:gz') as tar:
    for member in members:
        if member.name.endswith(target_file):
            found_file = member
            break

if found_file:
    print(f"✓ Found: {found_file.name}")
    print(f"  Size: {found_file.size} bytes")
    print(f"  Full path: {found_file.name}")
else:
    print(f"✗ File {target_file} not found in archive")

# %%