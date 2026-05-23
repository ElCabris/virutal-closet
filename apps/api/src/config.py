from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # App
    environment: str = "development"
    ai_enabled: bool = False

    # Database
    database_url: str = "postgresql+asyncpg://crayoli:crayoli@localhost:5432/crayoli_dev"

    # Redis
    redis_url: str = "redis://localhost:6379/0"

    # Auth
    jwt_secret: str = "dev-secret-change-in-production-32chars"
    jwt_access_token_expire_minutes: int = 15
    jwt_refresh_token_expire_days: int = 7
    jwt_algorithm: str = "HS256"

    # Storage
    aws_access_key_id: str = ""
    aws_secret_access_key: str = ""
    aws_region: str = "us-east-1"
    s3_bucket_name: str = "crayoli-images"

    # AI
    anthropic_api_key: str = ""
    pinecone_api_key: str = ""
    pinecone_index_name: str = "crayoli-garments"
    openweather_api_key: str = ""

    # CORS
    cors_origins: list[str] = ["http://localhost:3000"]

    # Founder user
    founder_email: str = "ana@crayoli.app"
    founder_name: str = "Ana María"


@lru_cache
def get_settings() -> Settings:
    return Settings()
