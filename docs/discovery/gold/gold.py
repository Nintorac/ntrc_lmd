#%% [markdown]
"""
# Gold Layer

## Tables
"""
#%%
import lakh_midi_dataset
#%%
%%sql
ATTACH 'hf://datasets/nintorac/ntrc_lakh_midi/lakh_remote.duckdb' AS lakh_remote;
use lakh_remote.ntrc_lmd_gold;
show tables;
# %%
