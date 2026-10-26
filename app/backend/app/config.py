from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Runtime configuration. Every value can be overridden by an env var
    (prefixed AETHER_), which is how Kubernetes/GitOps manifests inject config."""

    model_config = SettingsConfigDict(env_prefix="AETHER_", env_file=".env", extra="ignore")

    app_name: str = "aether-backend"
    version: str = "0.1.0"
    environment: str = "dev"
    log_level: str = "INFO"
    # Comma-separated list of allowed browser origins (only needed if the
    # frontend is served from a different origin than the API).
    cors_origins: str = "http://localhost:5173"
    # Optional shared secret for write endpoints (e.g. CI webhooks).
    # Inject from a Kubernetes Secret, never commit it.
    api_token: str = ""

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
