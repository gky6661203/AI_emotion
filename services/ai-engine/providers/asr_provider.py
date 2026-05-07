from abc import ABC, abstractmethod
from typing import Dict

class ASRProvider(ABC):
    @abstractmethod
    async def transcribe(self, file_url: str) -> str:
        pass

class PlaceholderASRProvider(ASRProvider):
    """Placeholder ASR - returns mock transcription"""

    async def transcribe(self, file_url: str) -> str:
        return "这是一段语音转文字的占位内容。实际ASR服务后期接入。"