## lmd_full.tar.gz

contains midi files

First 10 files:
  lmd_full (0 bytes)
  lmd_full/f (0 bytes)
  lmd_full/f/f8b9a90823dd6af25ac67eaf8fef6a43.mid (63516 bytes)
  lmd_full/f/f85a225a881d7e97643c2dc4e3a8fe9a.mid (56745 bytes)
  lmd_full/f/fdc9a30d6512b6165da48340c290a0c4.mid (48022 bytes)
  lmd_full/f/fee5e8ef07701433da3a79cfd9d82703.mid (35018 bytes)
  lmd_full/f/f2c6082099e6007dec7abbd60bcbf3b8.mid (16087 bytes)
  lmd_full/f/f8bf40a64acf9bfecadb76e01eda4660.mid (27061 bytes)
  lmd_full/f/f15fe73b0ee71771a82dca58773f4adf.mid (11414 bytes)
  lmd_full/f/f20cb8be7bfeca7ffc06900aa120f41f.mid (43960 bytes)


## lmd_matched_h5.tar.gz

Contains song metadata

First 10 files:
  lmd_matched_h5 (0 bytes)
  lmd_matched_h5/L (0 bytes)
  lmd_matched_h5/L/L (0 bytes)
  lmd_matched_h5/L/L/L (0 bytes)
  lmd_matched_h5/L/L/L/TRLLLJH12903CC3D7C.h5 (174127 bytes)
  lmd_matched_h5/L/L/L/TRLLLKU128F425FF8B.h5 (354947 bytes)
  lmd_matched_h5/L/L/M (0 bytes)
  lmd_matched_h5/L/L/M/TRLLMMQ128F423119C.h5 (247141 bytes)
  lmd_matched_h5/L/L/M/TRLLMYI128F933BD4A.h5 (225423 bytes)
  lmd_matched_h5/L/L/P (0 bytes)

File types found:
  .h5: 31034 files

Keys in the H5 file:
  analysis: <class 'h5py._hl.group.Group'>
  metadata: <class 'h5py._hl.group.Group'>
  musicbrainz: <class 'h5py._hl.group.Group'>

--- analysis ---
Group with 16 items:
  bars_confidence: dataset (70,) float64
  bars_start: dataset (70,) float64
  beats_confidence: dataset (282,) float64
  beats_start: dataset (282,) float64
  sections_confidence: dataset (10,) float64
  sections_start: dataset (10,) float64
  segments_confidence: dataset (422,) float64
  segments_loudness_max: dataset (422,) float64
  segments_loudness_max_time: dataset (422,) float64
  segments_loudness_start: dataset (422,) float64
  segments_pitches: dataset (422, 12) float64
  segments_start: dataset (422,) float64
  segments_timbre: dataset (422, 12) float64
  songs: dataset (1,) [('analysis_sample_rate', '<i4'), ('audio_md5', 'S32'), ('danceability', '<f8'), ('duration', '<f8'), ('end_of_fade_in', '<f8'), ('energy', '<f8'), ('idx_bars_confidence', '<i4'), ('idx_bars_start', '<i4'), ('idx_beats_confidence', '<i4'), ('idx_beats_start', '<i4'), ('idx_sections_confidence', '<i4'), ('idx_sections_start', '<i4'), ('idx_segments_confidence', '<i4'), ('idx_segments_loudness_max', '<i4'), ('idx_segments_loudness_max_time', '<i4'), ('idx_segments_loudness_start', '<i4'), ('idx_segments_pitches', '<i4'), ('idx_segments_start', '<i4'), ('idx_segments_timbre', '<i4'), ('idx_tatums_confidence', '<i4'), ('idx_tatums_start', '<i4'), ('key', '<i4'), ('key_confidence', '<f8'), ('loudness', '<f8'), ('mode', '<i4'), ('mode_confidence', '<f8'), ('start_of_fade_out', '<f8'), ('tempo', '<f8'), ('time_signature', '<i4'), ('time_signature_confidence', '<f8'), ('track_id', 'S32')]
  tatums_confidence: dataset (563,) float64
  tatums_start: dataset (563,) float64

--- metadata ---
Group with 5 items:
  artist_terms: dataset (18,) |S256
  artist_terms_freq: dataset (18,) float64
  artist_terms_weight: dataset (18,) float64
  similar_artists: dataset (100,) |S20
  songs: dataset (1,) [('analyzer_version', 'S32'), ('artist_7digitalid', '<i4'), ('artist_familiarity', '<f8'), ('artist_hotttnesss', '<f8'), ('artist_id', 'S32'), ('artist_latitude', '<f8'), ('artist_location', 'S1024'), ('artist_longitude', '<f8'), ('artist_mbid', 'S40'), ('artist_name', 'S1024'), ('artist_playmeid', '<i4'), ('genre', 'S1024'), ('idx_artist_terms', '<i4'), ('idx_similar_artists', '<i4'), ('release', 'S1024'), ('release_7digitalid', '<i4'), ('song_hotttnesss', '<f8'), ('song_id', 'S32'), ('title', 'S1024'), ('track_7digitalid', '<i4')]

--- musicbrainz ---
Group with 3 items:
  artist_mbtags: dataset (0,) |S256
  artist_mbtags_count: dataset (0,) int32
  songs: dataset (1,) [('idx_artist_mbtags', '<i4'), ('year', '<i4')]


Extracting songs data from first 10 H5 files...
Processing file 1: lmd_matched_h5/L/L/L/TRLLLJH12903CC3D7C.h5
Processing file 2: lmd_matched_h5/L/L/L/TRLLLKU128F425FF8B.h5
Processing file 3: lmd_matched_h5/L/L/M/TRLLMMQ128F423119C.h5
Processing file 4: lmd_matched_h5/L/L/M/TRLLMYI128F933BD4A.h5
Processing file 5: lmd_matched_h5/L/L/P/TRLLPXN128F14A9E72.h5
Processing file 6: lmd_matched_h5/L/L/P/TRLLPYU128F425C486.h5
Processing file 7: lmd_matched_h5/L/L/T/TRLLTCK128F9307CEF.h5
Processing file 8: lmd_matched_h5/L/L/I/TRLLISC128F4277C42.h5
Processing file 9: lmd_matched_h5/L/L/I/TRLLIYR128F42A357E.h5
Processing file 10: lmd_matched_h5/L/L/I/TRLLIZP128F4251BBB.h5

Analysis songs DataFrame shape: (10, 33)
Analysis columns: ['analysis_sample_rate', 'audio_md5', 'danceability', 'duration', 'end_of_fade_in', 'energy', 'idx_bars_confidence', 'idx_bars_start', 'idx_beats_confidence', 'idx_beats_start', 'idx_sections_confidence', 'idx_sections_start', 'idx_segments_confidence', 'idx_segments_loudness_max', 'idx_segments_loudness_max_time', 'idx_segments_loudness_start', 'idx_segments_pitches', 'idx_segments_start', 'idx_segments_timbre', 'idx_tatums_confidence', 'idx_tatums_start', 'key', 'key_confidence', 'loudness', 'mode', 'mode_confidence', 'start_of_fade_out', 'tempo', 'time_signature', 'time_signature_confidence', 'track_id', 'filename']

Metadata songs DataFrame shape: (10, 22)
Metadata columns: ['analyzer_version', 'artist_7digitalid', 'artist_familiarity', 'artist_hotttnesss', 'artist_id', 'artist_latitude', 'artist_location', 'artist_longitude', 'artist_mbid', 'artist_name', 'artist_playmeid', 'genre', 'idx_artist_terms', 'idx_similar_artists', 'release', 'release_7digitalid', 'song_hotttnesss', 'song_id', 'title', 'track_7digitalid', 'filename']

Musicbrainz songs DataFrame shape: (10, 4)
Musicbrainz columns: ['idx_artist_mbtags', 'year', 'filename']

## match_scores.json

matches midi files to song metadata

sample

```json
{"TRRNARX128F4264AEB": {"cd3b9c8bb118575bcd712cffdba85fce": 0.7040202098544246}, "TRWMHMP128EF34293F": {"c3da6699f64da3db8e523cbbaa80f384": 0.7321245522741104, "d8392424ea57a0fe6f65447680924d37": 0.7476196649194942}, "TRWOLRE128F427D710": {"728c3dbdc9b47142dc8f725c6805c259": 0.6720550712904779, "468be2f5dd31a1ba444b8018d8e8c7ad": 0.7359987644809902, "1882595a3905adc9f5258a0c7f12e84d": 0.668445525775334, "6610c6e885ae4524ec6c3db50cc3ab53": 0.6316134362439223, "03b77bd9334f18bddff53535fe6ca953": 0.6395130395002708, "64b53e1dc28ac96bc4a860ada0021bb0": 0.7226302373042208, "544aff782dcc97dfd317a47cc7b7899b": 0.6716007881421701, "ae4502a8dc4853d7efc9edb0c12f6682": 0.6614824548436951, "6c88022b86c00f7bd5d4d3e84ec1a075": 0.7359987644809902},...
```

## md5_to_paths.json

maps midi md5s to the original names of the midi file as scraped

```json
{"1c83fc02b8c57fbc2605900bb31793fb":["E\/Exaltasamba - Megastar.mid","Midis Samba e Pagode\/Exaltasamba - Megastar.mid","Midis Samba e Pagode\/Exaltasamba - Megastar.mid"],"fbcfdb9398bada87210d970ff3563a1e":["MIDIS POP E ROCK\/Lobao - A Queda.mid","Midis Pop e Rock\/Lobao - A Queda.mid","Midis Pop e Rock\/Lobao - A Queda.mid"],"6d6a6ecbdc8a9141e17346dbe4c0349e":["TV_Themes_www.tv-timewarp.co.uk_MIDIRip\/Rainbow.mid"],"7717b0e2e566e90e3e01497401863e82":["Beatles\/Happiness is a Warm Gun.mid","Beatles, The\/Happiness-Is-A-Warm-Gun.mid","Beatles, The\/Happiness-Is-A-Warm-Gun.mid","Beatles +GeorgeJohnPaulRingo\/HappinessIsAWarmGun.mid","Beatles +GeorgeJohnPaulRingo\/HappinessIsAWarmGun.mid","beatles\/warmgun.mid","Various Artists\/warmgun.mid","Beatles\/happiness_is_a_warm_gun.mid","beatles\/warmgun.mid","Various Artists\/warmgun.mid","beatles\/Happiness_Is_A_Warm_Gun.mid","H\/Happiness-Is-A-Warm-Gun.mid","Beatles, The\/Happiness-Is-A-Warm-Gun.mid","beatles\/warmgun.mid",...
```