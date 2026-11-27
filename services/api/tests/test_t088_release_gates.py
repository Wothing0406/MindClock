from pathlib import Path

from fastapi.testclient import TestClient
from pydantic import SecretStr

from app.config import Settings
from app.main import create_app


def _prod_settings(tmp_path: Path) -> Settings:
    db_file = tmp_path / 't088_prod.db'
    return Settings(
        app_env='production',
        database_url=f'sqlite+pysqlite:///{db_file.as_posix()}',
        gemini_api_key=SecretStr('AQ.TEST_FAKE_KEY'),
        gemini_mock_mode=True,
        local_dev_bearer_uid_fallback=False,
    )


def test_t088_wip_web_routes_disabled_in_production_and_download_page_available(tmp_path: Path) -> None:
    app = create_app(_prod_settings(tmp_path))
    with TestClient(app) as client:
        assert client.get('/demo').status_code == 404
        assert client.get('/product').status_code == 404

        dl = client.get('/download')
        assert dl.status_code == 200
        assert 'mindclock-android.apk' in dl.text
