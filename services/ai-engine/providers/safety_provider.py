from abc import ABC, abstractmethod
from typing import Dict

class SafetyProvider(ABC):
    @abstractmethod
    async def check_content(self, content: str) -> Dict:
        pass

class RulesSafetyProvider(SafetyProvider):
    """Rule-based safety check"""

    RISK_PATTERNS = {
        "suicide": ["自杀", "自残", "不想活", "死了算了", "轻生", "割腕"],
        "violence": ["杀人", "报复", "伤害", "攻击"],
        "harassment": ["侮辱", "谩骂", "诋毁"],
    }

    def __init__(self, threshold: float = 0.7):
        self.threshold = threshold

    async def check_content(self, content: str) -> Dict:
        content_lower = content.lower()

        risk_types = []
        max_risk = 0.0

        for risk_type, patterns in self.RISK_PATTERNS.items():
            for pattern in patterns:
                if pattern in content_lower:
                    risk_types.append(risk_type)
                    max_risk = max(max_risk, 0.8)
                    break

        is_safe = max_risk < self.threshold

        return {
            "is_safe": is_safe,
            "risk_level": "high" if max_risk >= 0.8 else "medium" if max_risk >= 0.5 else "low",
            "risk_types": risk_types,
            "suggestion": "需要人工介入" if not is_safe else "内容安全"
        }

def create_safety_provider() -> SafetyProvider:
    return RulesSafetyProvider()