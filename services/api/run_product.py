"""Run the local product UI without replacing the original demo."""
from pathlib import Path
import os
import subprocess
import sys
import argparse

import uvicorn


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=8010)
    args = parser.parse_args()
    api_dir = Path(__file__).resolve().parent
    os.chdir(api_dir)
    subprocess.run([sys.executable, '-m', 'alembic', 'upgrade', 'head'], check=True)
    print(f'\nMindClock: http://127.0.0.1:{args.port}/product\n', flush=True)
    uvicorn.run('app.main:app', host='127.0.0.1', port=args.port, log_level='info')
