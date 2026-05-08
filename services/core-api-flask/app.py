from flask import Flask, request, jsonify
import requests
import json

app = Flask(__name__)

AI_ENGINE_URL = "http://localhost:8090"

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"success": True, "message": "success", "data": {"status": "ok", "service": "core-api"}})

@app.route('/api/auth/anonymous', methods=['POST'])
def create_anonymous_user():
    data = request.get_json()
    nickname = data.get('nickname', '匿名用户')
    return jsonify({
        "success": True,
        "message": "success",
        "data": {
            "anonymous_token": "test-token-123",
            "nickname": nickname,
            "created_at": "2024-01-01T00:00:00Z"
        }
    })

@app.route('/api/chat/messages', methods=['POST'])
def send_message():
    data = request.get_json()
    content = data.get('content')
    
    try:
        ai_response = requests.post(
            f"{AI_ENGINE_URL}/v1/chat/completion",
            json={"message": content}
        )
        ai_response.raise_for_status()
        ai_data = ai_response.json()
        
        return jsonify({
            "success": True,
            "message": "success",
            "data": {
                "content": ai_data.get('content', 'AI 响应'),
                "message_id": data.get('message_id'),
                "sent_at": "2024-01-01T00:00:00Z"
            }
        })
    except Exception as e:
        return jsonify({
            "success": False,
            "message": str(e),
            "data": None
        })

@app.route('/api/private-letters', methods=['POST'])
def create_letter():
    data = request.get_json()
    return jsonify({
        "success": True,
        "message": "success",
        "data": {
            "id": "letter-123",
            "content": data.get('content'),
            "emotion_tag": "happy",
            "created_at": "2024-01-01T00:00:00Z"
        }
    })

@app.route('/api/private-letters', methods=['GET'])
def get_letters():
    return jsonify({
        "success": True,
        "message": "success",
        "data": {
            "letters": []
        }
    })

@app.route('/api/emotions/report', methods=['GET'])
def get_emotion_report():
    return jsonify({
        "success": True,
        "message": "success",
        "data": {
            "overall_mood": "neutral",
            "trend": "stable",
            "suggestions": ["保持心情愉快"]
        }
    })

@app.route('/api/recommendations/current', methods=['GET'])
def get_recommendations():
    return jsonify({
        "success": True,
        "message": "success",
        "data": {
            "recommendations": [
                {"type": "relax", "title": "听轻音乐", "priority": 1}
            ]
        }
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=True)