"""Use the running local Docker database for an isolated disposable test DB.

Credentials stay in memory; never print container environment or connection URL.
Run from services/api: .venv/Scripts/python scripts/run_progression_postgres.py
"""
import os
import subprocess
import sys
from sqlalchemy.engine import make_url


def main():
    result = subprocess.run(['docker', 'exec', 'api-api-1', 'python', '-c',
        'import os; print(os.environ["DATABASE_URL"])'], capture_output=True, text=True)
    if result.returncode:
        print('Cannot read local Docker DB configuration; no tests or DB changes made.')
        return 1
    try:
        url = make_url(result.stdout.strip()).set(host='127.0.0.1', port=5432)
        env = dict(os.environ)
        env['MINDCLOCK_TEST_POSTGRES_ADMIN_URL'] = url.render_as_string(hide_password=False)
    except Exception:
        print('Invalid local Docker DB configuration; no DB changes made.')
        return 1
    return subprocess.call([sys.executable, '-m', 'pytest',
        'tests/test_progression_postgres.py', '-q', '--tb=short'], env=env)


if __name__ == '__main__':
    raise SystemExit(main())
