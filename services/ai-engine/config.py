import os
from typing import Literal

class Config:
    LLM_PROVIDER: Literal["rules", "openai_compatible"] = os.getenv("LLM_PROVIDER", "rules")
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
    OPENAI_BASE_URL: str = os.getenv("OPENAI_BASE_URL", "https://api.openai.com/v1")
    LLM_MODEL: str = os.getenv("LLM_MODEL", "gpt-3.5-turbo")

    AI_ENGINE_HOST: str = os.getenv("AI_ENGINE_HOST", "0.0.0.0")
    AI_ENGINE_PORT: int = int(os.getenv("AI_ENGINE_PORT", "8090"))

    SAFETY_THRESHOLD: float = float(os.getenv("SAFETY_THRESHOLD", "0.7"))

config = Config()