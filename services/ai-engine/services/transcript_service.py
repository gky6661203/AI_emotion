from .asr_provider import ASRProvider, PlaceholderASRProvider

class TranscriptService:
    def __init__(self, asr_provider: ASRProvider = None):
        self.asr = asr_provider or PlaceholderASRProvider()

    async def transcribe(self, file_url: str) -> str:
        return await self.asr.transcribe(file_url)