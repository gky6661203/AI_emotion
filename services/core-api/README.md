# AI Emotion Core API

## Setup

```bash
cd services/core-api
cargo run
```

## Environment Variables

- `DATABASE_URL` - PostgreSQL connection string
- `REDIS_URL` - Redis connection string (default: redis://localhost:6379)
- `AI_ENGINE_URL` - AI Engine URL (default: http://localhost:8090)
- `SERVER_ADDR` - Server address (default: 0.0.0.0:8080)
- `RUST_LOG` - Log level (default: info)

## API Endpoints

- `GET /health` - Health check
- `POST /api/auth/anonymous` - Create anonymous user
- `POST /api/devices/bind` - Bind device
- `GET /api/devices` - List devices
- `POST /api/chat/messages` - Send message
- `POST /api/private-letters` - Create letter
- `GET /api/private-letters/:id` - Get letter
- `POST /api/voice-records` - Upload voice record
- `POST /api/voice-records/:id/transcribe` - Transcribe voice
- `POST /api/voice-records/:id/analyze` - Analyze voice
- `GET /api/recommendations/current` - Get recommendations
- `GET /api/emotions/report` - Get emotion report
- `WS /ws/devices/sync` - Device sync WebSocket