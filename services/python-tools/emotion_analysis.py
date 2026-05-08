#!/usr/bin/env python3
"""情绪分析工具 - 离线运行"""

import argparse
import json

EMOTION_KEYWORDS = {
    'happy': ['开心', '高兴', '快乐', '幸福', '愉快', '喜悦'],
    'sad': ['悲伤', '难过', '伤心', '痛苦', '失落', '沮丧'],
    'angry': ['愤怒', '生气', '恼火', '烦躁', '不满'],
    'anxious': ['焦虑', '紧张', '不安', '担心', '忧虑'],
    'lonely': ['孤独', '寂寞', '孤单', '空虚'],
    'neutral': []
}

RESPONSES = {
    'happy': '很高兴听到你分享这些！保持好心情。',
    'sad': '我理解你的感受，愿意陪伴你。',
    'angry': '深呼吸，试着冷静下来，我在这里倾听。',
    'anxious': '别太担心，试着慢慢放松。',
    'lonely': '你不是一个人，我在这里陪伴你。',
    'neutral': '感谢你的分享，继续说吧。'
}

def analyze_emotion(text):
    if not text:
        return {'emotion': 'neutral', 'intensity': 0.5, 'keywords': []}

    text_lower = text.lower()
    emotion_scores = {}

    for emotion, keywords in EMOTION_KEYWORDS.items():
        if emotion == 'neutral':
            continue
        score = sum(1 for kw in keywords if kw in text_lower)
        if score > 0:
            emotion_scores[emotion] = score

    if not emotion_scores:
        return {'emotion': 'neutral', 'intensity': 0.5, 'keywords': []}

    dominant_emotion = max(emotion_scores, key=emotion_scores.get)
    base_intensity = min(0.5 + emotion_scores[dominant_emotion] * 0.1, 1.0)
    detected_keywords = [kw for kw in EMOTION_KEYWORDS[dominant_emotion] if kw in text_lower]

    return {
        'emotion': dominant_emotion,
        'intensity': round(base_intensity, 2),
        'keywords': detected_keywords[:5],
        'response': RESPONSES.get(dominant_emotion, '感谢你的分享。')
    }

def main():
    parser = argparse.ArgumentParser(description='情绪分析工具')
    parser.add_argument('--text', type=str, required=True)
    args = parser.parse_args()

    result = analyze_emotion(args.text)
    print(json.dumps(result, ensure_ascii=False))

if __name__ == '__main__':
    main()
