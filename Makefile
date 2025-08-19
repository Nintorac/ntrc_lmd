# Lakh MIDI Dataset Download Makefile

# DBT configuration
DBT_PROFILES_DIR = ./lakh_midi_dbt
DBT_PROJECT_DIR = ./lakh_midi_dbt

# URLs for the dataset files
MATCH_SCORES_URL = http://hog.ee.columbia.edu/craffel/lmd/match_scores.json
LMD_FULL_URL = http://hog.ee.columbia.edu/craffel/lmd/lmd_full.tar.gz
LMD_MATCHED_H5_URL = http://hog.ee.columbia.edu/craffel/lmd/lmd_matched_h5.tar.gz
MD5_TO_PATHS_URL = http://hog.ee.columbia.edu/craffel/lmd/md5_to_paths.json

# File targets
MATCH_SCORES = match_scores.json
LMD_FULL = lmd_full.tar.gz
LMD_MATCHED_H5 = lmd_matched_h5.tar.gz
MD5_TO_PATHS = md5_to_paths.json


# Default target - download all files
data-build-bronze-download: $(MATCH_SCORES) $(LMD_FULL) $(LMD_MATCHED_H5) $(MD5_TO_PATHS)

# Download match_scores.json
$(MATCH_SCORES):
	@echo "Downloading match_scores.json..."
	wget -O $(MATCH_SCORES) $(MATCH_SCORES_URL)

# Download lmd_full.tar.gz
$(LMD_FULL):
	@echo "Downloading lmd_full.tar.gz..."
	wget -O $(LMD_FULL) $(LMD_FULL_URL)

# Download lmd_matched_h5.tar.gz
$(LMD_MATCHED_H5):
	@echo "Downloading lmd_matched_h5.tar.gz..."
	wget -O $(LMD_MATCHED_H5) $(LMD_MATCHED_H5_URL)

# Download md5_to_paths.json
$(MD5_TO_PATHS):
	@echo "Downloading md5_to_paths.json..."
	wget -O $(MD5_TO_PATHS) $(MD5_TO_PATHS_URL)

# Clean downloaded files
clean:
	rm -f $(MATCH_SCORES) $(LMD_FULL) $(LMD_MATCHED_H5) $(MD5_TO_PATHS)

# Show download status
status:
	@echo "Download status:"
	@ls -lh $(MATCH_SCORES) $(LMD_FULL) $(LMD_MATCHED_H5) $(MD5_TO_PATHS) 2>/dev/null || echo "Some files not downloaded yet"

# Download only the mapping files (smaller downloads)
maps: $(MATCH_SCORES) $(MD5_TO_PATHS)

# Download only the data files (larger downloads)
data: $(LMD_FULL) $(LMD_MATCHED_H5)

# DBT Build targets
# Create output directories
setup-dirs:
	@echo "Creating output directories..."
	mkdir -p data/silver_lakh_midi

# Run bronze pipeline to process raw data
data-build-bronze-process: setup-dirs
	@echo "Running bronze pipeline..."
	uv run bronze_pipeline.py

# Build static models (excluding incremental tagged models)
data-build-silver-static: setup-dirs
	@echo "Building static models..."
	dbt run --select tag:silver --exclude tag:incremental

# Build incremental models for all hex digits (0-9, a-f)
data-build-silver-incrementals:
	@echo "Building incremental models for all partitions..."
	@for digit in 0 1 2 3 4 5 6 7 8 9 a b c d e f; do \
		echo "Building partition: $$digit"; \
		dbt run --select tag:silver,tag:incremental --vars '{"partition_filter": "'$$digit'"}'; \
	done

data-test-silver:
	@echo "Running dbt tests..."
	dbt test --select tag:silver

# Build gold layer models
data-build-gold:
	@echo "Building gold layer models..."
	dbt run --select tag:gold

# Test gold layer models
data-test-gold:
	@echo "Running gold layer tests..."
	dbt test --select tag:gold

# Build complete bronze pipeline (download then process)
data-build-bronze-all: data-build-bronze-download data-build-bronze-process

# Build complete dataset (static first, then incrementals)
data-build-silver-all: data-build-silver-static data-build-silver-incrementals data-test-silver

# Build gold layer (build then test)
data-build-gold-all: data-build-gold data-test-gold

# Build complete pipeline (bronze -> silver -> gold)
data-build-all: data-build-bronze-all data-build-silver-all data-build-gold-all

# Jupyter Book targets
# Build the Jupyter Book
docs-build:
	@echo "Building Jupyter Book..."
	YDATA_SUPPRESS_BANNER=1 jupyter-book build docs/

# Clean Jupyter Book build artifacts
docs-clean:
	@echo "Cleaning Jupyter Book build artifacts..."
	jupyter-book clean docs/

# Serve the built book locally
docs-serve: docs-build
	@echo "Serving Jupyter Book locally..."
	@echo "Open http://localhost:8000 in your browser"
	cd docs/_build/html && python -m http.server 8000

.PHONY: all clean status maps data setup-dirs data-build-bronze-download data-build-bronze-process data-build-bronze-all data-build-silver-static data-build-silver-incrementals data-build-silver-all data-test-silver data-build-gold data-test-gold data-build-gold-all data-build-all docs-build docs-clean docs-serve docs-view