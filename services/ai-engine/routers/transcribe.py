from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

router = APIRouter(prefix="/v1", tags=["transcribe"])

class TranscribeRequest(BaseModel):
    file_url: str

class TranscribeResponse(BaseModel):
    transcript: str

async def get_transcriber():
    from main import transcript_service
    if transcript_service is None:
        raise HTTPException(status_code=503, detail="Transcript service not initialized")
    return transcript_service

@router.post("/transcribe", response_model=TranscribeResponse)
async def transcribe(
    request: TranscribeRequest,
    transcriber=Depends(get_transcriber)
):
    transcript = await transcriber.transcribe(request.file_url)
    return TranscribeResponse(transcript=transcript)