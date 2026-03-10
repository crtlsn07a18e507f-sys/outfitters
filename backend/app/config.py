from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "postgresql://style_user:style_pass@localhost:5432/style_db"
    anthropic_api_key: str = ""
    openweather_api_key: str = ""
    images_dir: str = "/app/images"
    max_image_size_mb: int = 10

    class Config:
        env_file = ".env"


settings = Settings()
