import { Router, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { execute, queryOne } from '../db';
import { AuthenticatedRequest, authMiddleware } from '../middleware/auth';
import { VoiceRecord } from '../models';
import { runPythonTool } from '../utils/pythonTools';

const router = Router();

router.use(authMiddleware);

router.post('/', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { file_url, duration_seconds } = req.body;
    const userId = req.user!.id;
    const now = new Date().toISOString();

    const recordId = uuidv4();
    await execute(
      `INSERT INTO voice_records (id, user_id, file_url, duration_seconds, risk_level, transcription_status, analysis_status, allow_ai_analysis, write_to_emotion_profile, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
      [recordId, userId, file_url, duration_seconds || null, 'low', 'pending', 'pending', true, true, now]
    );

    const record = await queryOne<VoiceRecord>(
      'SELECT * FROM voice_records WHERE id = $1',
      [recordId]
    );

    res.status(201).json({ voice_record: record });
  } catch (error) {
    console.error('Upload voice record error:', error);
    res.status(500).json({ error: 'Failed to upload voice record' });
  }
});

router.get('/:id', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { id } = req.params;
    const userId = req.user!.id;

    const record = await queryOne<VoiceRecord>(
      'SELECT * FROM voice_records WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL',
      [id, userId]
    );

    if (!record) {
      res.status(404).json({ error: 'Voice record not found' });
      return;
    }

    res.json({ voice_record: record });
  } catch (error) {
    console.error('Get voice record error:', error);
    res.status(500).json({ error: 'Failed to get voice record' });
  }
});

router.post('/:id/transcribe', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { id } = req.params;
    const userId = req.user!.id;

    const record = await queryOne<VoiceRecord>(
      'SELECT * FROM voice_records WHERE id = $1 AND user_id = $2',
      [id, userId]
    );

    if (!record) {
      res.status(404).json({ error: 'Voice record not found' });
      return;
    }

    await execute(
      'UPDATE voice_records SET transcription_status = $1 WHERE id = $2',
      ['processing', id]
    );

    const transcribeResult = await runPythonTool('voice_process.py', { file: record.file_url });
    let transcript = '转写处理中...';

    if (transcribeResult.success && transcribeResult.data) {
      const data = transcribeResult.data as { transcript?: string };
      transcript = data.transcript || transcript;
    }

    await execute(
      'UPDATE voice_records SET transcript = $1, transcription_status = $2 WHERE id = $3',
      [transcript, 'completed', id]
    );

    const updatedRecord = await queryOne<VoiceRecord>(
      'SELECT * FROM voice_records WHERE id = $1',
      [id]
    );

    res.json({ voice_record: updatedRecord, transcript });
  } catch (error) {
    console.error('Transcribe voice error:', error);
    res.status(500).json({ error: 'Failed to transcribe voice' });
  }
});

router.post('/:id/analyze', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { id } = req.params;
    const userId = req.user!.id;

    const record = await queryOne<VoiceRecord>(
      'SELECT * FROM voice_records WHERE id = $1 AND user_id = $2',
      [id, userId]
    );

    if (!record) {
      res.status(404).json({ error: 'Voice record not found' });
      return;
    }

    const textToAnalyze = record.transcript || '无转写内容';
    const emotionResult = await runPythonTool('emotion_analysis.py', { text: textToAnalyze });

    let emotion = 'neutral';
    let emotionIntensity = 0.5;

    if (emotionResult.success && emotionResult.data) {
      const data = emotionResult.data as { emotion?: string; intensity?: number };
      emotion = data.emotion || 'neutral';
      emotionIntensity = data.intensity || 0.5;
    }

    await execute(
      'UPDATE voice_records SET emotion = $1, emotion_intensity = $2, analysis_status = $3 WHERE id = $4',
      [emotion, emotionIntensity, 'completed', id]
    );

    if (record.write_to_emotion_profile) {
      const emotionRecordId = uuidv4();
      await execute(
        `INSERT INTO emotion_records (id, user_id, emotion, intensity, source, risk_detected, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [emotionRecordId, userId, emotion, emotionIntensity, 'voice', emotion === 'anxious' || emotion === 'angry', new Date().toISOString()]
      );
    }

    const updatedRecord = await queryOne<VoiceRecord>(
      'SELECT * FROM voice_records WHERE id = $1',
      [id]
    );

    res.json({
      voice_record: updatedRecord,
      emotion,
      emotion_intensity: emotionIntensity
    });
  } catch (error) {
    console.error('Analyze voice error:', error);
    res.status(500).json({ error: 'Failed to analyze voice' });
  }
});

export default router;
