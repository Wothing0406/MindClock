from functools import lru_cache
from typing import List

from pydantic import Field, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Cấu hình backend MindClock nạp từ biến môi trường / `.env`.

    `gemini_api_key` dùng kiểu `SecretStr` để không bao giờ lộ ra repr/log.
    """

    model_config = SettingsConfigDict(
        env_file='.env',
        env_file_encoding='utf-8',
        extra='ignore',
    )

    app_env: str = 'development'
    app_host: str = '0.0.0.0'
    app_port: int = 8000
    log_level: str = 'INFO'
    cors_allow_origins: str = 'http://localhost:3000,http://10.0.2.2:8000'

    database_url: str = 'sqlite+pysqlite:///./mindclock_local.db'

    gemini_api_key: SecretStr = Field(default=SecretStr(''))
    gemini_api_base_url: str = 'https://generativelanguage.googleapis.com'
    gemini_primary_model: str = 'gemini-3.8-flash'
    gemini_fast_model: str = 'gemini-3.5-flash-lite'
    gemini_live_model: str = 'gemini-3.8-live'
    gemini_live_api_version: str = 'v1alpha'
    gemini_live_token_ttl_seconds: int = 600
    gemini_timeout_seconds: float = 15.0
    gemini_mock_mode: bool = False

    firebase_project_id: str = ''
    local_dev_bearer_uid_fallback: bool = True

    @property
    def cors_origins_list(self) -> List[str]:
        return [
            origin.strip()
            for origin in self.cors_allow_origins.split(',')
            if origin.strip()
        ]

    @property
    def is_sqlite(self) -> bool:
        return self.database_url.startswith('sqlite')

    @property
    def has_gemini_key(self) -> bool:
        return bool(self.gemini_api_key.get_secret_value().strip())

    def get_gemini_secret(self) -> str:
        return self.gemini_api_key.get_secret_value().strip()


@lru_cache
def get_settings() -> Settings:
    return Settings()
