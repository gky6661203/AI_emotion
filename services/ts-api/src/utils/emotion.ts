import { v4 as uuidv4 } from 'uuid';
import { execute } from '../db';
import { runPythonTool } from './pythonTools';

export interface EmotionAnalysisResult {
  emotion: string;
  intensity: number;
  keywords: string[];
  response?: string;
  summary: string;
  risk_detected: boolean;
  risk_level: 'low' | 'medium' | 'high' | 'critical';
  risk_types: string[];
}

const RISK_PATTERNS: Record<string, string[]> = {
  suicide: ['自杀', '自残', '不想活', '轻生', '割腕', '结束生命', '活不下去'],
  violence: ['杀人', '报复', '伤害别人', '攻击', '打死'],
  crisis: ['崩溃', '绝望', '撑不住', '没人能帮我', '彻底完了']
};

export function detectRisk(text: string): Pick<EmotionAnalysisResult, 'risk_detected' | 'risk_level' | 'risk_types'> {
  const normalized = (text || '').toLowerCase();
  const riskTypes: string[] = [];

  for (const [type, patterns] of Object.entries(RISK_PATTERNS)) {
    if (patterns.some((pattern) => normalized.includes(pattern.toLowerCase()))) {
      riskTypes.push(type);
    }
  }

  if (riskTypes.includes('suicide')) {
    return { risk_detected: true, risk_level: 'critical', risk_types: riskTypes };
  }

  if (riskTypes.includes('violence')) {
    return { risk_detected: true, risk_level: 'high', risk_types: riskTypes };
  }

  if (riskTypes.length > 0) {
    return { risk_detected: true, risk_level: 'medium', risk_types: riskTypes };
  }

  return { risk_detected: false, risk_level: 'low', risk_types: [] };
}

export async function analyzeText(text: string): Promise<EmotionAnalysisResult> {
  const emotionResult = await runPythonTool('emotion_analysis.py', { text });
  const data = emotionResult.success && emotionResult.data && typeof emotionResult.data === 'object'
    ? emotionResult.data as { emotion?: string; intensity?: number; keywords?: string[]; response?: string; summary?: string }
    : {};
  const risk = detectRisk(text);
  const emotion = data.emotion || 'neutral';
  const intensity = typeof data.intensity === 'number' ? data.intensity : 0.5;
  const keywords = Array.isArray(data.keywords) ? data.keywords : [];

  return {
    emotion,
    intensity,
    keywords,
    response: data.response,
    summary: data.summary || `检测到${emotion}情绪，强度${intensity.toFixed(2)}`,
    ...risk
  };
}

export async function createEmotionRecord(
  userId: string,
  analysis: EmotionAnalysisResult,
  source: 'text' | 'voice' | 'behavior' | 'explicit',
  sourceId?: string
): Promise<string> {
  const emotionRecordId = uuidv4();
  await execute(
    `INSERT INTO emotion_records (id, user_id, emotion, intensity, source, source_id, keywords, ai_summary, risk_detected, created_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
    [
      emotionRecordId,
      userId,
      analysis.emotion,
      analysis.intensity,
      source,
      sourceId || null,
      analysis.keywords,
      analysis.summary,
      analysis.risk_detected,
      new Date().toISOString()
    ]
  );
  return emotionRecordId;
}

export async function createRiskEventIfNeeded(
  userId: string,
  analysis: EmotionAnalysisResult,
  source: string,
  sourceId: string | undefined,
  content: string
): Promise<string | null> {
  if (!analysis.risk_detected) return null;

  const riskEventId = uuidv4();
  await execute(
    `INSERT INTO risk_events (id, user_id, event_type, severity, source, source_id, content_preview, ai_analysis, notification_sent, handled, created_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, false, false, $9)`,
    [
      riskEventId,
      userId,
      analysis.risk_types[0] || 'emotional_crisis',
      analysis.risk_level,
      source,
      sourceId || null,
      content.slice(0, 200),
      analysis.summary,
      new Date().toISOString()
    ]
  );

  await execute(
    'UPDATE users SET risk_level = $1, updated_at = $2 WHERE id = $3',
    [analysis.risk_level, new Date().toISOString(), userId]
  );

  return riskEventId;
}
