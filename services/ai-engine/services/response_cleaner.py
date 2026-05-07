from typing import Dict, List

class ResponseCleaner:
    """Cleans and validates LLM responses"""

    def __init__(self):
        self.max_length = 2000
        self.blocked_patterns = [
            "password",
            "api_key",
            "secret",
        ]

    def clean(self, response: str) -> str:
        if not response:
            return ""

        cleaned = response.strip()

        cleaned = self._remove_sensitive_info(cleaned)

        if len(cleaned) > self.max_length:
            cleaned = cleaned[:self.max_length] + "..."

        return cleaned

    def _remove_sensitive_info(self, text: str) -> str:
        import re

        for pattern in self.blocked_patterns:
            text = re.sub(rf'{pattern}:\s*\S+', f'{pattern}: [REDACTED]', text, flags=re.IGNORECASE)

        return text