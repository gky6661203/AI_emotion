from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from config import config
from providers.llm_provider import LLMProviderFactory
from services.emotion_analyzer import EmotionAnalyzer
from services.transcript_service import TranscriptService
from services.recommendation_engine import RecommendationEngine
from services.response_cleaner import ResponseCleaner

ai_client = None
emotion_analyzer = None
transcript_service = None
recommendation_engine = None
response_cleaner = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    global ai_client, emotion_analyzer, transcript_service, recommendation_engine, response_cleaner

    llm_provider = LLMProviderFactory.create(config.LLM_PROVIDER)
    ai_client = llm_provider
    emotion_analyzer = EmotionAnalyzer(llm_provider)
    transcript_service = TranscriptService()
    recommendation_engine = RecommendationEngine(llm_provider)
    response_cleaner = ResponseCleaner()

    yield

    ai_client = None
    emotion_analyzer = None
    transcript_service = None
    recommendation_engine = None
    response_cleaner = None

app = FastAPI(
    title="AI Emotion Engine",
    version="0.1.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from routers import health, chat, emotion, transcribe, recommendation

app.include_router(health.router)
app.include_router(chat.router)
app.include_router(emotion.router)
app.include_router(transcribe.router)
app.include_router(recommendation.router)