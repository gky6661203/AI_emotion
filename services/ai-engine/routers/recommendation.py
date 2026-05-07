from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import List, Optional

router = APIRouter(prefix="/v1", tags=["recommendation"])

class RecommendRequest(BaseModel):
    emotion_state: Optional[dict] = None
    limit: int = 5

class RecommendationItem(BaseModel):
    type: str
    title: str
    description: Optional[str] = None
    priority: int

class RecommendResponse(BaseModel):
    recommendations: List[RecommendationItem]

async def get_engine():
    from main import recommendation_engine
    if recommendation_engine is None:
        raise HTTPException(status_code=503, detail="Recommendation engine not initialized")
    return recommendation_engine

@router.post("/recommend/current", response_model=RecommendResponse)
async def get_recommendations(
    request: RecommendRequest,
    engine=Depends(get_engine)
):
    recs = await engine.get_recommendations(request.emotion_state, request.limit)
    return RecommendResponse(recommendations=recs)