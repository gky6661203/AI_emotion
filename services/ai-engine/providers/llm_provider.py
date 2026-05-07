from abc import ABC, abstractmethod
from typing import Optional, Dict, List
import httpx

from config import config

class LLMProvider(ABC):
    @abstractmethod
    async def chat_completion(self, message: str, context: Dict) -> str:
        pass

    @abstractmethod
    async def analyze_emotion(self, text: str) -> Dict:
        pass

class RulesProvider(LLMProvider):
    """Rule-based responses for development/testing"""

    EMOTION_KEYWORDS = {
        "happy": ["开心", "高兴", "快乐", "喜悦", "愉快", "太好了", "棒"],
        "sad": ["难过", "伤心", "痛苦", "悲伤", "沮丧", "失落", "郁闷"],
        "angry": ["生气", "愤怒", "恼火", "烦躁", "不满", "气恼"],
        "anxious": ["焦虑", "担心", "紧张", "不安", "害怕", "恐惧", "惶恐"],
        "lonely": ["孤独", "寂寞", "孤单", "无聊", "没人", "一个人"],
        "grateful": ["感谢", "谢谢", "感激", "感恩", "多谢"],
        "confused": ["困惑", "迷茫", "不懂", "怎么办", "不清楚"],
    }

    RISK_KEYWORDS = ["自杀", "自残", "不想活", "死了", "轻生", "割腕"]

    COMPASSIONATE_RESPONSES = {
        "happy": "听起来你今天心情不错！有什么好事发生了吗？",
        "sad": "我理解你现在的感受，愿意说说发生了什么事吗？",
        "angry": "有什么事情让你感到不满吗？说说看，我在这里倾听。",
        "anxious": "别太担心，试着深呼吸。我们可以聊聊是什么让你感到焦虑。",
        "lonely": "我理解孤独的感觉，有时候说出来会好受一些。",
        "grateful": "很高兴你有这样的心情！有什么特别想感谢的事情吗？",
        "confused": "生活中总会有困惑的时候，我们可以一起理清思路。",
    }

    def __init__(self):
        self.responses = self.COMPASSIONATE_RESPONSES

    async def chat_completion(self, message: str, context: Dict) -> str:
        emotion = self._detect_emotion(message)

        if emotion in self.responses:
            return self.responses[emotion]

        return "感谢你的分享。继续说吧，我在这里倾听你。"

    async def analyze_emotion(self, text: str) -> Dict:
        emotion = self._detect_emotion(text)
        intensity = self._calculate_intensity(text, emotion)
        keywords = self._extract_keywords(text)
        risk_detected = self._check_risk(text)

        return {
            "emotion": emotion,
            "intensity": intensity,
            "keywords": keywords,
            "risk_detected": risk_detected,
            "summary": f"用户表达{emotion}情绪，强度{intensity:.2f}"
        }

    def _detect_emotion(self, text: str) -> str:
        text_lower = text.lower()

        for emotion, keywords in self.EMOTION_KEYWORDS.items():
            for keyword in keywords:
                if keyword in text_lower:
                    return emotion

        return "neutral"

    def _calculate_intensity(self, text: str, emotion: str) -> float:
        text_lower = text.lower()
        intensity_boosters = ["非常", "特别", "极其", "十分", "太", "好"]

        base_intensity = 0.5

        for booster in intensity_boosters:
            if booster in text_lower:
                base_intensity += 0.1

        if len(text) > 100:
            base_intensity += 0.1

        return min(base_intensity, 1.0)

    def _extract_keywords(self, text: str) -> List[str]:
        keywords = []
        for emotion, emotion_keywords in self.EMOTION_KEYWORDS.items():
            for keyword in emotion_keywords:
                if keyword in text:
                    keywords.append(keyword)
                    break

        return keywords[:5]

    def _check_risk(self, text: str) -> bool:
        for keyword in self.RISK_KEYWORDS:
            if keyword in text:
                return True
        return False

class OpenAICompatibleProvider(LLMProvider):
    def __init__(self, api_key: str = None, base_url: str = None, model: str = None):
        self.api_key = api_key or config.OPENAI_API_KEY
        self.base_url = base_url or config.OPENAI_BASE_URL
        self.model = model or config.LLM_MODEL

    async def chat_completion(self, message: str, context: Dict) -> str:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                f"{self.base_url}/chat/completions",
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": self.model,
                    "messages": [{"role": "user", "content": message}]
                }
            )

            if response.status_code == 200:
                data = response.json()
                return data["choices"][0]["message"]["content"]
            else:
                return "AI service error"

    async def analyze_emotion(self, text: str) -> Dict:
        prompt = f"""分析以下文本的情绪状态，返回JSON格式：
        {{
            "emotion": "情绪类别",
            "intensity": 0.0-1.0,
            "keywords": ["关键词1", "关键词2"],
            "risk_detected": true/false,
            "summary": "简短总结"
        }}

        文本：{text}"""

        result = await self.chat_completion(prompt, {})

        try:
            import json
            start = result.find("{")
            end = result.rfind("}") + 1
            if start != -1 and end != 0:
                return json.loads(result[start:end])
        except:
            pass

        return {
            "emotion": "neutral",
            "intensity": 0.5,
            "keywords": [],
            "risk_detected": False,
            "summary": "无法分析"
        }

class LLMProviderFactory:
    @staticmethod
    def create(provider_type: str = None) -> LLMProvider:
        provider_type = provider_type or config.LLM_PROVIDER

        if provider_type == "openai_compatible":
            return OpenAICompatibleProvider()
        else:
            return RulesProvider()