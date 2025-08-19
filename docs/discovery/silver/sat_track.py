#%% [markdown]
"""
# Tracks

Found in the sat_midi_file table for the silver layer.

"""
#%% tags=["hide-input"]
import lakh_midi_dataset
from ydata_profiling import ProfileReport
import plotly.express as px
import plotly.graph_objects as go
import plotly.io as pio
import pandas as pd
import numpy as np
from functools import partial

# Configure Plotly for static output in Jupyter Book
pio.renderers.default = "png"
#%%
%%sql
ATTACH 'hf://datasets/nintorac/ntrc_lakh_midi/lakh_remote.duckdb' AS lakh_remote;

#%% [markdown]
"""
## Feature Analysis

First we show the data profile of the simple features stored in the track satellite.


"""
# %%
%%sql -o track_df -t df
select 
    track_hk,
    audio_md5,
    analysis_sample_rate,
    danceability,
    duration,
    end_of_fade_in,
    energy,
    key_signature_id,
    key_confidence,
    loudness,
    mode_id,
    mode_confidence,
    start_of_fade_out,
    tempo,
    time_signature,
    time_signature_confidence,
    title,
    genre,
    year,
    analyzer_version,
    song_id,
    song_hotttnesss,
    idx_bars_confidence,
    idx_bars_start,
    idx_beats_confidence,
    idx_beats_start,
    idx_sections_confidence,
    idx_sections_start,
    idx_segments_confidence,
    idx_segments_loudness_max,
    idx_segments_loudness_max_time,
    idx_segments_loudness_start,
    idx_segments_pitches,
    idx_segments_start,
    idx_segments_timbre,
    idx_tatums_confidence,
    idx_tatums_start,
    -- skip heavy array columns for now
    --bars_start,
    --bars_confidence,
    --beats_start,
    --beats_confidence,
    --sections_start,
    --sections_confidence,
    --segments_start,
    --segments_confidence,
    --segments_loudness_max,
    --segments_loudness_max_time,
    --segments_loudness_start,
    --segments_pitches,
    --segments_timbre,
    --tatums_start,
    --tatums_confidence,
    load_date,
    record_source,
    partition_col
from lakh_remote.sat_track 
#%% [markdown]
"""
We display a data profile on the dataset, this contains various format specific analysis and 
visualisations to help understand the shape of the data.

```{tip}
Check out the correlation between year and loudness to see how music has been getting louder
over time
```
"""
# %% tags=["hide-input", "hide-output"]
# run dataset profiling
profile = ProfileReport(track_df, progress_bar=False)
#%%
profile.to_notebook_iframe()
# %% [markdown]
"""
## Time Series Analysis

Now we'll have a look at some of the Echonest time series features,
for that we'll pick a couple of random songs

```{note}
In the following plots, we show the prediction confidence by the size of the markers, the higher the confidence, the smaller the marker.
```
"""

# %%
%%sql -o track_timeseries_df -t df
select 
    track_hk,
    title,
    year,
    bars_start,
    bars_confidence,
    beats_start,
    beats_confidence,
    sections_start,
    sections_confidence,
    segments_start,
    segments_confidence,
    segments_loudness_max,
    segments_loudness_max_time,
    segments_loudness_start,
    segments_pitches,
    segments_timbre,
    tatums_start,
    tatums_confidence,
from lakh_remote.sat_track 
where track_hk in (
    '029f0cec6a749b64f45f27b8a7c56125',
    '02a93439e9627559dbc54f3a66f69c8c',
    '00d99d980159c5f67340a12debe54eae'
)
#%% [markdown]
"""
### Bars Analysis
**Bars** (also called measures) represent the primary metrical structure of music. A bar is a segment of time defined by a given number of beats.

"""

#%% tags=["hide-input"]
def create_combined_data(df, start_col, confidence_col, metric_name):
    """Create combined dataframe for faceted plotting"""
    combined_data = []
    
    for _, row in df.iterrows():
        if row[start_col] is not None and row[confidence_col] is not None:
            try:
                track_data = pd.DataFrame({
                    'time': row[start_col],
                    'confidence': row[confidence_col],
                    'track': f"{row['title'][:20]}..." if len(row['title']) > 20 else row['title'],
                    'year': row['year'],
                    'track_id': row['track_hk'][:8]
                })
                combined_data.append(track_data)
            except Exception as e:
                print(f"Warning: Skipping track {row['track_hk']} for {metric_name}: {e}")
                continue
    
    return pd.concat(combined_data, ignore_index=True) if combined_data else pd.DataFrame()

def create_delta_data(df, start_col, confidence_col, metric_name):
    """Create delta time dataframe for any rhythmic element"""
    combined_data = []
    
    for _, row in df.iterrows():
        if row[start_col] is not None and row[confidence_col] is not None:
            try:
                times = row[start_col]
                confidences = row[confidence_col]
                
                # Calculate time deltas between consecutive events
                if len(times) > 1:
                    time_deltas = [times[i] - times[i-1] for i in range(1, len(times))]
                    # Use confidence from the second event in each pair
                    delta_confidences = confidences[1:]
                    # Use the second event's time as x-axis
                    delta_times = times[1:]
                    
                    track_data = pd.DataFrame({
                        'time': delta_times,
                        'time_delta': time_deltas,
                        'confidence': delta_confidences,
                        'inv_confidence': [1 - c for c in delta_confidences],
                        'track': f"{row['title']}" if pd.notna(row['title']) else 'Unknown',
                        'year': row['year'],
                        'track_id': row['track_hk'][:8]
                    })
                    combined_data.append(track_data)
            except Exception as e:
                print(f"Warning: Skipping track {row['track_hk']} for {metric_name}: {e}")
                continue
    
    return pd.concat(combined_data, ignore_index=True) if combined_data else pd.DataFrame()

# Bars time deltas visualization
bars_data = create_delta_data(track_timeseries_df, 'bars_start', 'bars_confidence', 'bars')
if not bars_data.empty:
    fig = px.scatter(bars_data, x='time', y='time_delta',
                    color='track', size='inv_confidence',
                    title="Bars Time Deltas Across Tracks (first 60s)",
                    hover_data=['year', 'track_id', 'confidence'],
                    range_x=(0, 60),
                    labels={'time_delta': 'Time Delta (seconds)', 'time': 'Time (seconds)'})
    
    # Calculate Hz range for secondary axis
    min_delta = bars_data['time_delta'].min()
    max_delta = bars_data['time_delta'].max()
    
    if min_delta > 0 and max_delta > 0:
        min_hz = 1 / max_delta
        max_hz = 1 / min_delta
        
        fig.update_layout(
            height=400,
            yaxis=dict(title="Time Delta (seconds)"),
            yaxis2=dict(
                title="Frequency (Hz)",
                overlaying="y",
                side="right",
                range=[min_hz, max_hz],
                tickmode='linear',
                tick0=min_hz,
                dtick=(max_hz - min_hz) / 5
            ),
            legend=dict(
                orientation="h",
                x=0.5,
                y=-0.2,
                xanchor="center",
                yanchor="top",
                bgcolor="rgba(255,255,255,0.8)"
            )
        )
        
        import plotly.graph_objects as go
        fig.add_trace(
            go.Scatter(
                x=[bars_data['time'].min()],
                y=[min_hz], 
                yaxis='y2',
                mode='markers',
                marker=dict(opacity=0),
                showlegend=False,
                hoverinfo='skip'
            )
        )
    
    fig.show()
else:
    print("No valid bars data found")

#%% [markdown]
"""
### Beats Analysis
**Beats** are the basic time units of music - the regular pulse that listeners
tap their feet to. In the Echo Nest system, beats represent the perceived tactus or main pulse of the music.

"""

#%% tags=['hide-input']
# Beats time deltas visualization
beats_data = create_delta_data(track_timeseries_df, 'beats_start', 'beats_confidence', 'beats')
if not beats_data.empty:
    fig = px.scatter(beats_data, x='time', y='time_delta',
                    color='track', size='inv_confidence',
                    title="Beats Time Deltas Across Tracks (first 30s)",
                    hover_data=['year', 'track_id', 'confidence'],
                    range_x=(0, 30),
                    labels={'time_delta': 'Time Delta (seconds)', 'time': 'Time (seconds)'})
    
    # Calculate BPM range for secondary axis
    min_delta = beats_data['time_delta'].min()
    max_delta = beats_data['time_delta'].max()
    
    if min_delta > 0 and max_delta > 0:
        min_bpm = 60 / max_delta
        max_bpm = 60 / min_delta
        
        fig.update_layout(
            height=400,
            yaxis=dict(title="Time Delta (seconds)"),
            yaxis2=dict(
                title="BPM",
                overlaying="y",
                side="right",
                range=[min_bpm, max_bpm],
                tickmode='linear',
                tick0=min_bpm,
                dtick=(max_bpm - min_bpm) / 5
            ),
            legend=dict(
                orientation="h",
                x=0.5,
                y=-0.2,
                xanchor="center",
                yanchor="top",
                bgcolor="rgba(255,255,255,0.8)"
            )
        )
        
        import plotly.graph_objects as go
        fig.add_trace(
            go.Scatter(
                x=[beats_data['time'].min()],
                y=[min_bpm], 
                yaxis='y2',
                mode='markers',
                marker=dict(opacity=0),
                showlegend=False,
                hoverinfo='skip'
            )
        )
    
    fig.show()
else:
    print("No valid beats data found")

#%% [markdown]
"""
### Sections Analysis
**Sections** identify large-scale structural elements of songs such as verses, choruses, bridges, and instrumental solos. 
They are defined by significant changes in rhythm, timbre, or harmonic content.
"""

#%% tags=['hide-input']
# Sections time deltas visualization
sections_data = create_delta_data(track_timeseries_df, 'sections_start', 'sections_confidence', 'sections')
if not sections_data.empty:
    fig = px.scatter(sections_data, x='time', y='time_delta',
                    color='track', size='inv_confidence',
                    title="Sections Time Deltas Across Tracks",
                    hover_data=['year', 'track_id', 'confidence'],
                    labels={'time_delta': 'Time Delta (seconds)', 'time': 'Time (seconds)'})
    
    # Calculate Hz range for secondary axis
    min_delta = sections_data['time_delta'].min()
    max_delta = sections_data['time_delta'].max()
    
    if min_delta > 0 and max_delta > 0:
        min_hz = 1 / max_delta
        max_hz = 1 / min_delta
        
        fig.update_layout(
            height=400,
            yaxis=dict(title="Time Delta (seconds)"),
            yaxis2=dict(
                title="Frequency (Hz)",
                overlaying="y",
                side="right",
                range=[min_hz, max_hz],
                tickmode='linear',
                tick0=min_hz,
                dtick=(max_hz - min_hz) / 5
            ),
            legend=dict(
                orientation="h",
                x=0.5,
                y=-0.2,
                xanchor="center",
                yanchor="top",
                bgcolor="rgba(255,255,255,0.8)"
            )
        )
        
        import plotly.graph_objects as go
        fig.add_trace(
            go.Scatter(
                x=[sections_data['time'].min()],
                y=[min_hz], 
                yaxis='y2',
                mode='markers',
                marker=dict(opacity=0),
                showlegend=False,
                hoverinfo='skip'
            )
        )
    
    fig.show()
else:
    print("No valid sections data found")

#%% [markdown]
"""
### Segments Analysis
**Segments** are short-duration sound entities (typically under a second) that are relatively uniform in timbre and harmony.
They represent the most granular level of Echo Nest's temporal analysis.
"""

#%% tags=['hide-input']
# Segments visualization
def create_segments_data(df):
    """Create segments dataframe with multiple metrics"""
    combined_data = []
    
    for _, row in df.iterrows():
        if (row['segments_start'] is not None and 
            row['segments_confidence'] is not None and 
            row['segments_loudness_max'] is not None):
            try:
                track_data = pd.DataFrame({
                    'time': row['segments_start'],
                    'confidence': row['segments_confidence'],
                    'inv_confidence': 1-row['segments_confidence'],
                    'loudness_max': row['segments_loudness_max'],
                    'loudness_max_time': row['segments_loudness_max_time'] if row['segments_loudness_max_time'] is not None else [0] * len(row['segments_start']),
                    'loudness_start': row['segments_loudness_start'] if row['segments_loudness_start'] is not None else [0] * len(row['segments_start']),
                    'track': f"{row['title'][:20]}..." if len(row['title']) > 20 else row['title'],
                    'year': row['year'],
                    'track_id': row['track_hk'][:8]
                })
                combined_data.append(track_data)
            except Exception as e:
                print(f"Warning: Skipping track {row['track_hk']} for segments: {e}")
                continue
    
    return pd.concat(combined_data, ignore_index=True) if combined_data else pd.DataFrame()

segments_data = create_segments_data(track_timeseries_df)

# Loudness visualization
fig2 = px.scatter(segments_data, x='time', y='loudness_max',
                    color='track', size='inv_confidence',
                    title="Segments Loudness Analysis Across Tracks",
                    hover_data=['year', 'track_id'],
                    range_x=(0,4),
                    labels={
                        'loudness_max': 'Max Loudness (dB)',
                        'time': 'Time (s)',
                    }
                    )
fig2.update_layout(height=400)
fig2.show()

#%% [markdown]
"""
### Pitch Chroma Analysis
**Pitch chroma vectors** are 12-dimensional representations of harmonic content,
corresponding to the 12 pitch classes of Western music: C, C#, D, D#, E, F, F#, G, G#, **Pitch chroma vectors** are 12-dimensional representations of harmonic content, corresponding to the 12 pitch classes of Western music: C, C#, D, D#, E, F, F#, G, G#, A, A#, B.A, A#, B.
"""

#%% tags=['hide-input']
# tags: ["hide-input"]
def create_pitch_subplots(df, n_segments):
    """Create pitch chroma heatmaps using subplots"""
    # Filter for rows with valid pitch data
    valid_rows = []
    for _, row in df.iterrows():
        if row['segments_pitches'] is not None and row['segments_start'] is not None:
            valid_rows.append(row)
    
    if not valid_rows:
        print("No valid pitch data found")
        return
    
    # Create subplots
    from plotly.subplots import make_subplots
    import plotly.graph_objects as go
    
    track_titles = [f"{row['title']}" for row in valid_rows]
    
    fig = make_subplots(
        rows=len(valid_rows), cols=1,
        subplot_titles=track_titles,
        shared_xaxes=False,
        vertical_spacing=0.15
    )
    
    for i, row in enumerate(valid_rows):
        try:
            pitches = np.stack(row['segments_pitches'])
            times = row['segments_start']
            
            fig.add_trace(
                go.Heatmap(
                    z=pitches.T[:, :n_segments],
                    x=times[:n_segments],
                    y=['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'],
                    colorscale='Viridis',
                    showscale=i==0,
                    colorbar=dict(title="Pitch Intensity") if i==0 else None
                ),
                row=i+1, col=1
            )
        except Exception as e:
            print(f"Warning: Skipping pitch visualization for track {row['track_hk']}: {e}")
    
    fig.update_layout(
        title=f"Pitch Chroma Analysis Across Tracks ({n_segments} segments)",
        height=200 * len(valid_rows),
        showlegend=False
    )
    
    # Update axes labels
    fig.update_yaxes(title_text="Pitch Class", row=1, col=1)
    fig.update_xaxes(title_text="Time (seconds)", row=len(valid_rows), col=1)
    
    fig.show()

create_pitch_subplots(track_timeseries_df, 30)

#%% tags=['hide-input']
create_pitch_subplots(track_timeseries_df, 150)

#%% tags=['hide-input']
create_pitch_subplots(track_timeseries_df, 300)

#%% [markdown]
"""
### Timbre Analysis
**Timbre vectors** are 12-dimensional representations capturing the "tone color" or spectral characteristics of audio segments.
These describe perceptual qualities like brightness, roughness, and spectral shape.
"""

#%% tags=['hide-input']
# Timbre heatmaps using subplots
def create_timbre_subplots(df, n_segments=30):
    """Create timbre heatmaps using subplots"""
    # Filter for rows with valid timbre data
    valid_rows = []
    for _, row in df.iterrows():
        if row['segments_timbre'] is not None and row['segments_start'] is not None:
            valid_rows.append(row)
    
    if not valid_rows:
        print("No valid timbre data found")
        return
    
    # Create subplots
    from plotly.subplots import make_subplots
    import plotly.graph_objects as go
    
    track_titles = [f"{row['title']}" for row in valid_rows]
    
    fig = make_subplots(
        rows=len(valid_rows), cols=1,
        subplot_titles=track_titles,
        shared_xaxes=False,
        vertical_spacing=0.15
    )
    
    for i, row in enumerate(valid_rows):
        try:
            timbres = np.stack(row['segments_timbre'])
            times = row['segments_start']
            # raise ValueError(timbres.shape, times[:8].shape, row['segments_timbre'].shape)
            
            fig.add_trace(
                go.Heatmap(
                    z=timbres.T[:,:n_segments],
                    x=times[:n_segments],
                    y=[f'Timbre_{j+1}' for j in range(12)],
                    colorscale='Plasma',
                    showscale=i==0,
                    colorbar=dict(title="Timbre Intensity") if i==0 else None
                ),
                row=i+1, col=1
            )
        except Exception as e:
            raise
            print(f"Warning: Skipping timbre visualization for track {row['track_hk']}: {e}")
    
    fig.update_layout(
        title=f"Timbre Analysis Across Tracks (first {n_segments} segments)", 
        height=200 * len(valid_rows),
        showlegend=False
    )
    
    # Update axes labels
    fig.update_yaxes(title_text="Timbre Dimension", row=1, col=1)
    fig.update_xaxes(title_text="Time (seconds)", row=len(valid_rows), col=1)
    
    fig.show()

create_timbre_subplots(track_timeseries_df, 30)
#%% tags=['hide-input']
create_timbre_subplots(track_timeseries_df, 300)

#%% tags=['hide-input']
create_timbre_subplots(track_timeseries_df, 3000)

#%% [markdown]
"""
### Tatums Analysis
[**Tatums**](https://en.wikipedia.org/wiki/Tatum_(music)) represent the smallest regular pulse that listeners intuitively infer from musical timing.
Named after jazz pianist Art Tatum "whose tatum was faster than all others",
tatums capture micro-rhythmic subdivisions.

"""

#%% tags=['hide-input']
# Tatums visualization - time deltas between tatums
def create_tatums_delta_data(df):
    """Create tatums dataframe with time deltas between consecutive tatums"""
    combined_data = []
    
    for _, row in df.iterrows():
        if row['tatums_start'] is not None and row['tatums_confidence'] is not None:
            try:
                times = row['tatums_start']
                confidences = row['tatums_confidence']
                
                # Calculate time deltas between consecutive tatums
                if len(times) > 1:
                    time_deltas = [times[i] - times[i-1] for i in range(1, len(times))]
                    # Use confidence from the second tatum in each pair
                    delta_confidences = confidences[1:]
                    # Use the second tatum's time as x-axis
                    delta_times = times[1:]
                    
                    track_data = pd.DataFrame({
                        'time': delta_times,
                        'time_delta': time_deltas,
                        'confidence': delta_confidences,
                        'track': f"{row['title']}" if pd.notna(row['title']) else 'Unknown',
                        'year': row['year'],
                        'track_id': row['track_hk'][:8]
                    })
                    combined_data.append(track_data)
            except Exception as e:
                print(f"Warning: Skipping track {row['track_hk']} for tatums: {e}")
                continue
    
    return pd.concat(combined_data, ignore_index=True) if combined_data else pd.DataFrame()

#%% tags=['hide-input']
# Tatums time deltas visualization
tatums_data = create_tatums_delta_data(track_timeseries_df)
fig2 = px.line(tatums_data, x='time', y='time_delta',
                    color='track', 
                    title="Tatums Time Deltas Across Tracks (first 100s)",
                    hover_data=['year', 'track_id', 'confidence'],
                    range_x=(0, 100),
                    labels={'time_delta': 'Time Delta (seconds)', 'time': 'Time (seconds)'})

# Calculate Hz range for secondary axis
min_delta = tatums_data['time_delta'].min()
max_delta = tatums_data['time_delta'].max()

if min_delta > 0 and max_delta > 0:
    # Convert to Hz: 1 / time_delta
    min_hz = 1 / max_delta
    max_hz = 1 / min_delta
    
    # Add secondary y-axis for Hz
    fig2.update_layout(
        height=400,
        yaxis=dict(title="Time Delta (seconds)"),
        yaxis2=dict(
            title="Frequency (Hz)",
            overlaying="y",
            side="right",
            range=[min_hz, max_hz],
            tickmode='linear',
            tick0=min_hz,
            dtick=(max_hz - min_hz) / 5
        ),
        # Position legend below plot to avoid covering data
        legend=dict(
            orientation="h",
            x=0.5,
            y=-0.2,
            xanchor="center",
            yanchor="top",
            bgcolor="rgba(255,255,255,0.8)"
        )
    )
    
    # Add invisible trace to force secondary axis to appear
    import plotly.graph_objects as go
    fig2.add_trace(
        go.Scatter(
            x=[tatums_data['time'].min()],
            y=[min_hz], 
            yaxis='y2',
            mode='markers',
            marker=dict(opacity=0),
            showlegend=False,
            hoverinfo='skip'
        )
    )

fig2.show()

#%% [markdown]
"""
#### Tatums Condfidence

Here we show the  confidence in the tatums predictions over the first 100s
"""

#%% tags=['hide-input']
# Original tatums confidence visualization
tatums_confidence_data = create_combined_data(track_timeseries_df, 'tatums_start', 'tatums_confidence', 'tatums')
fig1 = px.scatter(tatums_confidence_data, x='time', y='confidence',
                    color='track',
                    title="Tatums Confidence Across Tracks (first 100s)",
                    hover_data=['year', 'track_id'],
                    range_x=(0, 100))
fig1.update_layout(height=400)
fig1.show()



#%% [markdown]
"""
## Summary
This analysis provides a comprehensive view of the musical structure and acoustic features in the Lakh MIDI Dataset:

- **Rhythmic hierarchy**: From tatums (smallest) to sections (largest)
- **Harmonic content**: Pitch chroma vectors showing chord progressions
- **Timbral characteristics**: Spectral features capturing sound texture
- **Temporal patterns**: How musical elements evolve over time

The faceted visualizations enable comparison across different tracks, revealing both common patterns and unique characteristics in the dataset.
"""

#%%