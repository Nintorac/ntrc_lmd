#%% [markdown]
"""
# Midi files

Found in the sat_midi_file table for the silver layer.

"""
#%%
import lakh_midi_dataset

%load_ext magic_duckdb
#%%
%%sql
ATTACH 'hf://datasets/nintorac/ntrc_lakh_midi/lakh_remote.duckdb' AS lakh_remote;
use lakh_remote;
show tables;
# %%
%%sql -o midi_file_df
select *
from sat_midi_file 
limit 100
# %%
