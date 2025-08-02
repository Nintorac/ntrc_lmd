import h5py
import io
import numpy as np
import pandas as pd

def extract_h5_to_dict(file_content: bytes) -> dict:
    """
    Extract H5 file content to a nested dictionary structure
    """
    def dataset_to_dict(dataset):
        """Convert h5py dataset to python dict/list"""
        data = dataset[:]
        
        # Handle structured arrays (like songs data)
        if data.dtype.names:
            if len(data) == 1:
                # Single record - convert to dict
                record = data[0]
                return {field: convert_value(record[field]) for field in data.dtype.names}
            else:
                # Multiple records - convert to list of dicts
                return [
                    {field: convert_value(record[field]) for field in data.dtype.names}
                    for record in data
                ]
        else:
            # Regular arrays
            return data.tolist()
    
    def convert_value(value):
        """Convert numpy/h5py values to python types"""
        if isinstance(value, (np.ndarray)):
            return value.tolist()
        elif isinstance(value, np.bytes_):
            return value.decode('utf-8')
        elif isinstance(value, (np.integer, np.floating)):
            return value.item()
        else:
            return value
    
    def group_to_dict(group):
        """Recursively convert h5py group to dict"""
        result = {}
        for key in group.keys():
            item = group[key]
            if isinstance(item, h5py.Group):
                result[key] = group_to_dict(item)
            elif isinstance(item, h5py.Dataset):
                result[key] = dataset_to_dict(item)
        return result
    
    with h5py.File(io.BytesIO(file_content), 'r') as h5_file:
        return group_to_dict(h5_file)
