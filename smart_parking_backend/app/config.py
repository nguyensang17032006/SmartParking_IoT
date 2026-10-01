import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv


@dataclass(frozen=True)
class Settings:
    supabase_url: str
    supabase_secret_key: str
    device_api_key: str

    @classmethod
    def from_env(cls):
        load_dotenv(Path(__file__).resolve().parents[1] / ".env")
        values = {
            "supabase_url": os.getenv("SUPABASE_URL", "").strip(),
            "supabase_secret_key": (
                os.getenv("SUPABASE_SECRET_KEY")
                or os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
            ).strip(),
            "device_api_key": os.getenv("DEVICE_API_KEY", "").strip(),
        }
        missing = [name for name, value in values.items() if not value]
        if missing:
            raise RuntimeError("Thiếu cấu hình backend: " + ", ".join(missing))
        return cls(**values)
