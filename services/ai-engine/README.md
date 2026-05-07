# AI Emotion Engine

## Setup

```bash
cd services/ai-engine
pip install -r requirements.txt
uvicorn main:app --reload --port 8090
```

## API Endpoints

- `GET /health` - Health check
- `POST /v1/chat/completion` - Chat completion
- `POST /v1/analyze/emotion` - Emotion analysis
- `POST /v1/transcribe` - Voice transcription
- `POST /v1/recommend/current` - Get recommendations