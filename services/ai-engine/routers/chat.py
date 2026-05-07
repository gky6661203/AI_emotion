from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional

from providers.llm_provider import LLMProvider
from services.response_cleaner import ResponseCleaner

router = APIRouter(prefix="/v1", tags=["chat"])

class ChatRequest(BaseModel):
    message: str
    message_id: Optional[str] = None
    context: Optional[dict] = None

class ChatResponse(BaseModel):
    content: str
    message_id: Optional[str] = None

async def get_llm_provider():
    from main import ai_client
    if ai_client is None:
        raise HTTPException(status_code=503, detail="AI service not initialized")
    return ai_client

async def get_cleaner():
    from main import response_cleaner
    if response_cleaner is None:
        raise HTTPException(status_code=503, detail="AI service not initialized")
    return response_cleaner

@router.post("/chat/completion", response_model=ChatResponse)
async def chat_completion(
    request: ChatRequest,
    llm: LLMProvider = Depends(get_llm_provider),
    cleaner: ResponseCleaner = Depends(get_cleaner)
):
    response = await llm.chat_completion(request.message, request.context or {})

    cleaned = cleaner.clean(response)

    return ChatResponse(content=cleaned, message_id=request.message_id)