import { apiService } from '../services/ApiService';

export interface AIEmotionResult {
  emotion: string;
  intensity: number;
  keywords: string[];
  risk_detected: boolean;
  summary: string;
}

export class AIService {
  async analyzeEmotion(text: string): Promise<AIEmotionResult> {
    try {
      let response = await fetch('http://10.16.106.237:8090/v1/analyze/emotion', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ text })
      });

      if (response.ok) {
        return await response.json() as AIEmotionResult;
      }

      return this.fallbackEmotionAnalysis(text);
    } catch {
      return this.fallbackEmotionAnalysis(text);
    }
  }

  private fallbackEmotionAnalysis(text: string): AIEmotionResult {
    let emotion = 'neutral';
    let intensity = 0.5;

    let emotionKeywords: Record<string, string[]> = {
      'happy': ['开心', '高兴', '快乐', '太好了', '棒'],
      'sad': ['难过', '伤心', '悲伤', '痛苦'],
      'anxious': ['焦虑', '担心', '紧张', '害怕'],
      'angry': ['生气', '愤怒', '恼火'],
      'lonely': ['孤独', '寂寞', '一个人']
    };

    for (let [em, keywords] of Object.entries(emotionKeywords)) {
      for (let keyword of keywords) {
        if (text.includes(keyword)) {
          emotion = em;
          intensity = 0.6;
          break;
        }
      }
      if (emotion !== 'neutral') break;
    }

    return {
      emotion,
      intensity,
      keywords: [],
      risk_detected: false,
      summary: `检测到${emotion}情绪`
    };
  }

  getEmotionEmoji(emotion: string): string {
    let emojiMap: Record<string, string> = {
      'happy': '😊',
      'sad': '😢',
      'angry': '😠',
      'anxious': '😰',
      'lonely': '😔',
      'neutral': '😐'
    };
    return emojiMap[emotion] || '😐';
  }

  getEmotionColor(emotion: string): string {
    let colorMap: Record<string, string> = {
      'happy': '#FFD700',
      'sad': '#4169E1',
      'angry': '#DC143C',
      'anxious': '#FF8C00',
      'lonely': '#9370DB',
      'neutral': '#808080'
    };
    return colorMap[emotion] || '#808080';
  }
}

export let aiService = new AIService();