#!/usr/bin/env python3
"""
AI Emotion System Smoke Test
Tests all major API endpoints
"""

import os
import sys
import json
import asyncio
import httpx

CORE_API_URL = os.getenv("CORE_API_URL", "http://localhost:8080")
AI_ENGINE_URL = os.getenv("AI_ENGINE_URL", "http://localhost:8090")
TIMEOUT = 10

async def test_health(client, url, name):
    try:
        response = await client.get(f"{url}/health", timeout=TIMEOUT)
        if response.status_code == 200:
            print(f"[OK] {name} is healthy")
            return True
        else:
            print(f"[FAIL] {name} returned status {response.status_code}")
            return False
    except Exception as e:
        print(f"[FAIL] {name} is not reachable: {e}")
        return False

async def test_anonymous_user(client):
    try:
        response = await client.post(
            f"{CORE_API_URL}/api/auth/anonymous",
            json={"campus": "测试校区", "enrollment_year": 2024},
            timeout=TIMEOUT
        )
        if response.status_code == 200:
            data = response.json()
            print(f"[OK] Anonymous user created: {data['user']['id']}")
            return data['token']
        else:
            print(f"[FAIL] Create anonymous user failed: {response.status_code}")
            return None
    except Exception as e:
        print(f"[FAIL] Create anonymous user: {e}")
        return None

async def test_device_binding(client, token):
    try:
        response = await client.post(
            f"{CORE_API_URL}/api/devices/bind",
            json={
                "device_id": "test_device_001",
                "device_type": "phone",
                "device_name": "测试手机"
            },
            headers={"Authorization": f"Bearer {token}"},
            timeout=TIMEOUT
        )
        if response.status_code == 200:
            data = response.json()
            print(f"[OK] Device bound: {data['device']['id']}")
            return True
        else:
            print(f"[FAIL] Device binding failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"[FAIL] Device binding: {e}")
        return False

async def test_chat_message(client, token):
    try:
        response = await client.post(
            f"{CORE_API_URL}/api/chat/messages",
            json={"content": "我今天心情不太好"},
            headers={"Authorization": f"Bearer {token}"},
            timeout=TIMEOUT
        )
        if response.status_code == 200:
            data = response.json()
            print(f"[OK] Message sent: {data['message']['id']}")
            return True
        else:
            print(f"[FAIL] Send message failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"[FAIL] Send message: {e}")
        return False

async def test_private_letter(client, token):
    try:
        response = await client.post(
            f"{CORE_API_URL}/api/private-letters",
            json={"title": "测试树洞", "content": "这是我的一条测试树洞消息"},
            headers={"Authorization": f"Bearer {token}"},
            timeout=TIMEOUT
        )
        if response.status_code == 200:
            data = response.json()
            print(f"[OK] Letter created: {data['letter']['id']}")
            return data['letter']['id']
        else:
            print(f"[FAIL] Create letter failed: {response.status_code}")
            return None
    except Exception as e:
        print(f"[FAIL] Create letter: {e}")
        return None

async def test_voice_record(client, token):
    try:
        response = await client.post(
            f"{CORE_API_URL}/api/voice-records",
            json={"file_url": "file://test/voice_001.m4a", "duration_seconds": 30},
            headers={"Authorization": f"Bearer {token}"},
            timeout=TIMEOUT
        )
        if response.status_code == 200:
            data = response.json()
            print(f"[OK] Voice record created: {data['voice_record']['id']}")
            return data['voice_record']['id']
        else:
            print(f"[FAIL] Upload voice record failed: {response.status_code}")
            return None
    except Exception as e:
        print(f"[FAIL] Upload voice record: {e}")
        return None

async def test_voice_transcribe(client, token, record_id):
    try:
        response = await client.post(
            f"{CORE_API_URL}/api/voice-records/{record_id}/transcribe",
            headers={"Authorization": f"Bearer {token}"},
            json={},
            timeout=TIMEOUT
        )
        if response.status_code == 200:
            print(f"[OK] Transcription completed")
            return True
        else:
            print(f"[FAIL] Transcription failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"[FAIL] Transcription: {e}")
        return False

async def test_voice_analyze(client, token, record_id):
    try:
        response = await client.post(
            f"{CORE_API_URL}/api/voice-records/{record_id}/analyze",
            headers={"Authorization": f"Bearer {token}"},
            json={},
            timeout=TIMEOUT
        )
        if response.status_code == 200:
            data = response.json()
            print(f"[OK] Emotion analysis: {data['emotion']}")
            return True
        else:
            print(f"[FAIL] Emotion analysis failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"[FAIL] Emotion analysis: {e}")
        return False

async def test_recommendations(client, token):
    try:
        response = await client.get(
            f"{CORE_API_URL}/api/recommendations/current?limit=3",
            headers={"Authorization": f"Bearer {token}"},
            timeout=TIMEOUT
        )
        if response.status_code == 200:
            data = response.json()
            print(f"[OK] Got {len(data['recommendations'])} recommendations")
            return True
        else:
            print(f"[FAIL] Get recommendations failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"[FAIL] Get recommendations: {e}")
        return False

async def test_emotion_report(client, token):
    try:
        response = await client.get(
            f"{CORE_API_URL}/api/emotions/report?days=7",
            headers={"Authorization": f"Bearer {token}"},
            timeout=TIMEOUT
        )
        if response.status_code == 200:
            print(f"[OK] Emotion report generated")
            return True
        else:
            print(f"[FAIL] Get emotion report failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"[FAIL] Get emotion report: {e}")
        return False

async def main():
    print("=== AI Emotion Smoke Test ===" )
    print(f"Core API: {CORE_API_URL}")
    print(f"AI Engine: {AI_ENGINE_URL}")
    print()

    async with httpx.AsyncClient() as client:
        all_passed = True

        print("1. Testing Core API health...")
        all_passed = await test_health(client, CORE_API_URL, "Core API") and all_passed

        print()
        print("2. Testing AI Engine health...")
        all_passed = await test_health(client, AI_ENGINE_URL, "AI Engine") and all_passed

        print()
        print("3. Testing anonymous user creation...")
        token = await test_anonymous_user(client)
        if not token:
            all_passed = False
            print("Cannot proceed without token, stopping tests.")
            sys.exit(1)

        print()
        print("4. Testing device binding...")
        all_passed = await test_device_binding(client, token) and all_passed

        print()
        print("5. Testing chat message...")
        all_passed = await test_chat_message(client, token) and all_passed

        print()
        print("6. Testing private letter creation...")
        letter_id = await test_private_letter(client, token)
        if not letter_id:
            all_passed = False

        print()
        print("7. Testing voice record upload...")
        voice_id = await test_voice_record(client, token)
        if not voice_id:
            all_passed = False

        if voice_id:
            print()
            print("8. Testing voice transcription...")
            all_passed = await test_voice_transcribe(client, token, voice_id) and all_passed

            print()
            print("9. Testing voice emotion analysis...")
            all_passed = await test_voice_analyze(client, token, voice_id) and all_passed

        print()
        print("10. Testing recommendations...")
        all_passed = await test_recommendations(client, token) and all_passed

        print()
        print("11. Testing emotion report...")
        all_passed = await test_emotion_report(client, token) and all_passed

    print()
    print("=== Smoke Test Complete ===")
    if all_passed:
        print("All tests passed!")
        sys.exit(0)
    else:
        print("Some tests failed!")
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())