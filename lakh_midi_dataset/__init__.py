from pathlib import Path

# Load magic_duckdb extension automatically
try:
    from IPython import get_ipython
    ipython = get_ipython()
    if ipython is not None:
        import magic_duckdb
        magic_duckdb.MAGIC_NAME = "sql"
        ipython.run_line_magic('load_ext', 'magic_duckdb')
except ImportError:
    raise

project_dir = Path(__file__).parent.parent

__all__ = [
    'project_dir'
]