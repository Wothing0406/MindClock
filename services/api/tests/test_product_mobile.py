import re

from fastapi.testclient import TestClient

from app.config import Settings
from app.main import create_app


def test_product_mobile_routes_and_control_contract():
    app = create_app(Settings(app_env='test', database_url='sqlite+pysqlite:///:memory:', gemini_mock_mode=True))
    client = TestClient(app)
    page = client.get('/product')
    css = client.get('/product/style.css')
    js = client.get('/product/app.js')
    assert page.status_code == css.status_code == js.status_code == 200
    assert 'text/css' in css.headers['content-type']
    assert 'javascript' in js.headers['content-type']
    assert page.headers['cache-control'] == 'no-store'
    assert 'viewport-fit=cover' in page.text
    assert 'maximum-scale' not in page.text
    ids = re.findall(r'\bid="([^"]+)"', page.text)
    assert len(ids) == len(set(ids))
    for name in ['home', 'alarm', 'study', 'profile']:
        assert f'page-{name}' in ids and f'nav-{name}' in ids
    assert all(control in ids for control in re.findall(r"\$\('([^']+)'\)", js.text))
    assert 'env(safe-area-inset-bottom' in css.text
    assert 'prefers-reduced-motion' in css.text
    assert 'safety_status' in js.text
