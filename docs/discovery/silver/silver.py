#%% [markdown]
"""
# Silver Layer

## Structure

![High level silver layer structure](../../../data/assets/ntrc_lakh_schema_silver.png)

## Tables
"""
#%%
import lakh_midi_dataset
#%%
%%sql
ATTACH 'hf://datasets/nintorac/ntrc_lakh_midi/lakh_remote.duckdb' AS lakh_remote;
use lakh_remote;
show tables;
# %%
