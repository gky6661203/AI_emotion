from typing import Dict, List
from .response_cleaner import ResponseCleaner

class EmotionAnalyzer:
    def __init__(self, llm_provider):
        self.llm = llm_provider

    async def analyze(self, text: str, source: str = "text") -> Dict:
        result = await self.llm.analyze_emotion(text)

        return {
            "emotion": result.get("emotion", "neutral"),
            "intensity": result.get("intensity", 0.5),
            "keywords": result.get("keywords", []),
            "risk_detected": result.get("risk_detected", False),
            "summary": result.get("summary", "")
        }

    def _build_prompt(self, text: str) -> str:
        return f"""请分析以下文本的情绪状态，返回JSON格式：
        {{
            "emotion": "情绪类别",
            "intensity": 0.0-1.0,
            "keywords": ["关键词1", "关键词2"],
            "risk_detected": true/false,
            "summary": "简短总结"
        }}

        文本：{text}"""