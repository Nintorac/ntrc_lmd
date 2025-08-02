#!/usr/bin/env python3
"""
Bronze Layer Data Pipeline for Lakh MIDI Dataset
Processes raw source files into parquet format using dlt
"""

import json
import tarfile
from pathlib import Path
from typing import Iterator, Dict, Any
import io
from itertools import islice

import dlt
import h5py
import numpy as np
import pyarrow as pa
import pandas as pd


from lakh_midi_dataset.h5_utils import extract_h5_to_dict


@dlt.resource(table_name="raw_midi_files", parallelized=True)
def process_midi_files() -> Iterator[pa.Table]:
    """
    Extract MIDI files from lmd_full.tar.gz and yield as arrow tables
    """
    def get_midi_rows():
        tar_path = "lmd_full.tar.gz"
        with tarfile.open(tar_path, 'r|gz') as tar:
            for member in tar:
                if member.isfile() and member.name.endswith('.mid'):
                    # Extract MD5 from filename stem
                    file_path = member.name
                    filename = Path(file_path).stem
                    midi_md5 = filename
                    
                    # Extract file content
                    file_obj = tar.extractfile(member)
                    if file_obj:
                        file_content = file_obj.read()
                        
                        yield {
                            "file_path": file_path,
                            "midi_md5": midi_md5,
                            "file_content": file_content,
                            "file_size_bytes": len(file_content)
                        }
    
    rows = get_midi_rows()
    while item_slice := list(islice(rows, 1000)):
        yield pa.Table.from_pandas(pd.DataFrame(item_slice))


@dlt.resource(table_name="h5_extract", parallelized=True)
def process_h5_files() -> Iterator[pa.Table]:
    """
    Extract H5 files from lmd_matched_h5.tar.gz and extract musicbrainz data
    """
    def get_h5_rows():
        tar_path = "lmd_matched_h5.tar.gz"
        with tarfile.open(tar_path, 'r|gz') as tar:
            for member in tar:
                if member.isfile() and member.name.endswith('.h5'):
                    # Extract track ID from filename stem
                    file_path = member.name
                    filename = Path(file_path).stem
                    track_id = filename
                    
                    # Extract file content
                    file_obj = tar.extractfile(member)
                    if file_obj:
                        file_content = file_obj.read()
                        
                        # Extract H5 data directly here
                        extracted_data = extract_h5_to_dict(file_content)
                        
                        yield {
                            "track_id": track_id,
                            "file_path": file_path,
                            "file_size_bytes": len(file_content),
                            **extracted_data
                        }
    
    rows = get_h5_rows()
    while item_slice := list(islice(rows, 20)):
        yield pa.Table.from_pandas(pd.DataFrame(item_slice))


@dlt.resource(table_name="raw_match_scores")
def process_match_scores() -> Iterator[pa.Table]:
    """
    Parse match_scores.json and flatten into records
    """
    def get_match_rows():
        with open("match_scores.json", 'r') as f:
            match_data = json.load(f)
        
        for track_id, midi_scores in match_data.items():
            for midi_md5, score in midi_scores.items():
                yield {
                    "track_id": track_id,
                    "midi_md5": midi_md5,
                    "match_score": score
                }
    
    rows = get_match_rows()
    while item_slice := list(islice(rows, 1000)):
        yield pa.Table.from_pandas(pd.DataFrame(item_slice))


@dlt.resource(table_name="raw_md5_paths", parallelized=True)
def process_md5_paths() -> Iterator[pa.Table]:
    """
    Parse md5_to_paths.json and flatten into records
    """
    def get_md5_rows():
        with open("md5_to_paths.json", 'r') as f:
            md5_data = json.load(f)
        
        for midi_md5, paths in md5_data.items():
            for order, path in enumerate(paths):
                yield {
                    "midi_md5": midi_md5,
                    "source_path": path,
                    "path_order": order
                }
    
    rows = get_md5_rows()
    while item_slice := list(islice(rows, 1000)):
        yield pa.Table.from_pandas(pd.DataFrame(item_slice))



def run_bronze_pipeline():
    """
    Main function to run the bronze layer pipeline
    """
    # Create pipeline
    pipeline = dlt.pipeline(
        pipeline_name="lakh_midi_bronze",
        destination="filesystem",
        dataset_name="bronze_lakh_midi",
        progress=dlt.progress.tqdm(colour="yellow")
    )
    
    print("Starting bronze layer data pipeline...")
    
    # Run all resources
    resources = [
        process_midi_files(),
        process_match_scores(),
        process_md5_paths(),
        process_h5_files(),
    ]
    
    print("Processing all resources in parallel...")
    load_info = pipeline.run(
        resources,
        loader_file_format="parquet"
    )
    print(f"Load info: {load_info}")
    
    print("Bronze pipeline completed successfully!")


if __name__ == "__main__":
    run_bronze_pipeline()