"""
애플리케이션 환경 설정
"""
from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    """환경 변수 기반 설정"""

    # 데이터베이스
    DATABASE_URL: str = "postgresql+asyncpg://meta_admin:meta1234@localhost:5432/datahub_meta"

    # CORS
    CORS_ORIGINS: str = "http://localhost:5173,http://localhost:3000"

    # 서버
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    DEBUG: bool = True

    # 페이지네이션 기본값
    DEFAULT_PAGE_SIZE: int = 50
    MAX_PAGE_SIZE: int = 200

    @property
    def cors_origins_list(self) -> List[str]:
        """CORS 허용 도메인 목록"""
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",")]

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
