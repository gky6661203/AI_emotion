from abc import ABC, abstractmethod

class ASRProvider(ABC):
    @abstractmethod
    async def transcribe(self, file_url: str) -> str:
        pass

class PlaceholderASRProvider(ASRProvider):
    async def transcribe(self, file_url: str) -> str:
        return "语音转写功能开发中..."