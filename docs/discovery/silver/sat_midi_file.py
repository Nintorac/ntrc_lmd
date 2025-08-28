#%% [markdown]
"""
# Midi files

Found in the sat_midi_file table for the silver layer.

"""
#%%
from lakh_midi_dataset.render_midi import render_midi_to_audio
import lakh_midi_dataset
from IPython.display import Audio, display, HTML
import io
import os

#%%
%%sql
ATTACH 'hf://datasets/nintorac/ntrc_lakh_midi/lakh_remote.duckdb' AS lakh_remote;

# %%
%%sql -o midi_file_df
select 
    midi_hk,
    file_content,
    file_size,
    load_date,
    record_source,
from lakh_remote.ntrc_lmd_silver.sat_midi_file 
where partition_col='0'
order by midi_hk
limit 3

#%% tags=["remove-output"]
# Create audio column by saving files to _static/audio directory
audio_dir = "../../_static/audio/silver"
midi_file_df['audio_path'] = midi_file_df.apply(
    lambda row: render_midi_to_audio(row['file_content'], audio_dir, row['midi_hk']), 
    axis=1
)

# %%
# Display MIDI File 1
row = midi_file_df.iloc[0]
print(f"MIDI File 1 (Hash Key: {row['midi_hk']})")
print(f"File size: {row['file_size']} bytes")
print(f"Source: {row['record_source']}")
display(HTML(f'<audio controls><source src="{row["audio_path"]}" type="audio/ogg"></audio>'))

# %%
# Display MIDI File 2
row = midi_file_df.iloc[1]
print(f"MIDI File 2 (Hash Key: {row['midi_hk']})")
print(f"File size: {row['file_size']} bytes")
print(f"Source: {row['record_source']}")
display(HTML(f'<audio controls><source src="{row["audio_path"]}" type="audio/ogg"></audio>'))

# %%
# Display MIDI File 3
row = midi_file_df.iloc[2]
print(f"MIDI File 3 (Hash Key: {row['midi_hk']})")
print(f"File size: {row['file_size']} bytes")
print(f"Source: {row['record_source']}")
display(HTML(f'<audio controls><source src="{row["audio_path"]}" type="audio/ogg"></audio>'))

#%%