from typing import Dict, List, Optional

class RecommendationEngine:
    def __init__(self, llm_provider):
        self.llm = llm_provider

    async def get_recommendations(
        self,
        emotion_state: Optional[Dict] = None,
        limit: int = 5
    ) -> List[Dict]:
        if emotion_state is None:
            return self._default_recommendations()[:limit]

        emotion = emotion_state.get("emotion", "neutral")
        intensity = emotion_state.get("intensity", 0.5)

        recommendations = self._generate_by_emotion(emotion, intensity)

        return recommendations[:limit]

    def _generate_by_emotion(self, emotion: str, intensity: float) -> List[Dict]:
        base_recs = []

        if emotion in ["sad", "lonely", "anxious"]:
            base_recs.extend([
                {"type": "companion", "title": "AI 陪伴聊天", "description": "随时在这里倾听你", "priority": 1},
                {"type": "treehole", "title": "写下心事", "description": "私密树洞，AI 帮你整理情绪", "priority": 2},
                {"type": "relaxation", "title": "放松内容", "description": "舒缓音乐和视频", "priority": 3},
            ])

            if intensity > 0.7:
                base_recs.append(
                    {"type": "resource", "title": "心理资源", "description": "专业心理调适技巧", "priority": 4}
                )

        elif emotion == "happy":
            base_recs.extend([
                {"type": "share", "title": "分享喜悦", "description": "记录美好时刻", "priority": 1},
                {"type": "social", "title": "匿名搭子", "description": "寻找志同道合的伙伴", "priority": 2},
            ])

        elif emotion == "angry":
            base_recs.extend([
                {"type": "vent", "title": "倾诉一下", "description": "说出来会好受些", "priority": 1},
                {"type": "relaxation", "title": "放松内容", "description": "深呼吸，舒缓一下", "priority": 2},
            ])

        else:
            base_recs.extend(self._default_recommendations())

        return base_recs

    def _default_recommendations(self) -> List[Dict]:
        return [
            {"type": "companion", "title": "AI 陪伴聊天", "description": "随时在这里倾听你", "priority": 1},
            {"type": "treehole", "title": "写下心事", "description": "私密树洞，AI 帮你整理情绪", "priority": 2},
            {"type": "voice", "title": "语音记录", "description": "说出你的感受", "priority": 3},
            {"type": "resource", "title": "心理资源", "description": "专业心理调适技巧", "priority": 4},
        ]