"""Khởi chạy nhanh máy chủ demo MindClock (PC + Android Emulator)."""
from pathlib import Path
import subprocess
import sys

import uvicorn


def main() -> None:
    api_dir = Path(__file__).resolve().parent
    # Bảo đảm schema SQLite local được migrate mới nhất trước khi mở server demo.
    subprocess.run(
        [sys.executable, '-m', 'alembic', 'upgrade', 'head'],
        cwd=str(api_dir),
        check=True,
    )
    print('MindClock Demo PC:      http://127.0.0.1:8000/demo')
    print('MindClock Swagger API:  http://127.0.0.1:8000/docs')
    print('Android Emulator URL:   http://10.0.2.2:8000/demo')
    uvicorn.run('app.main:app', host='0.0.0.0', port=8000, log_level='info')


if __name__ == '__main__':
    main()
