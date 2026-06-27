"""
Clinical ETL Cleaning Proxy Script
Author: Ravikant Yadav
Description: Proxies call to scripts/clean_data.py to ensure zero duplicate code.
"""

import sys
from pathlib import Path
import subprocess

if __name__ == "__main__":
    ROOT = Path(__file__).resolve().parents[1]
    script_path = ROOT / "scripts" / "clean_data.py"
    print(f"Proxy: Executing clinical ETL cleaning at {script_path}")
    result = subprocess.run([sys.executable, str(script_path)], capture_output=False)
    sys.exit(result.returncode)
