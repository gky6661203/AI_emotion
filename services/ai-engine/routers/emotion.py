from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import List, Optional

router = APIRouter(prefix="/v1", tags=["emotion"])

class EmotionRequest(BaseModel):
    text: str
    source: Optional[str] = "text"

class EmotionResponse(BaseModel):
    emotion: str
    intensity: float
    keywords: List[str]
    risk_detected: bool
    summary: str

async def get_analyzer():
    from main import emotion_analyzer
    if emotion_analyzer is None:
        raise HTTPException(status_code=503, detail="Emotion analyzer not initialized")
    return emotion_analyzer

@router.post("/analyze/emotion", response_model=EmotionResponse)
async def analyze_emotion(
    request: EmotionRequest,
    analyzer=Depends(get_analyzer)
):
    result = await analyzer.analyze(request.text, request.source)
    return EmotionResponse(**result)