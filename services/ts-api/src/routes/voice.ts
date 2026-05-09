import { Router, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { execute, query, queryOne } from '../db';
import { AuthenticatedRequest, authMiddleware } from '../middleware/auth';
import { VoiceRecord } from '../models';
import { runPythonTool } from '../utils/pythonTools';
import { analyzeText, createEmotionRecord, createRiskEventIfNeeded } from '../utils/emotion';

const router = Router();

router.use(authMiddleware);

router.get('/', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const limit = Math.min(parseInt(req.query.limit as string) || 50, 100);
    const records = await query<VoiceRecord>(
      'SELECT * FROM voice_records WHERE user_id = $1 AND deleted_at IS NULL ORDER BY created_at DESC LIMIT $2',
      [userId, limit]
    );
    res.json({ voice_records: records });
  } catch (error) {
    console.error('List voice records error:', error);
    res.status(500).json({ error: 'Failed to list voice records' });
  }
});

router.post('/', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const {
      file_url,
      duration_seconds,
      allow_ai_analysis = true,
      write_to_emotion_profile = true
    } = req.body;

    if (!file_url || typeof file_url !== 'string') {
      res.status(400).json({ error: 'file_url is required' });
      return;
    }

    const userId = req.user!.id;
    const now = new Date().toISOString();
    const recordId = uuidv4();

    await execute(
      `INSERT INTO voice_records (
        id, user_id, file_url, duration_seconds, risk_level, transcription_status, analysis_status,
        allow_ai_analysis, write_to_emotion_profile, created_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
      [recordId, userId, file_url, duration_seconds || null, 'low', 'pending', 'pending', allow_ai_analysis, write_to_emotion_profile, now]
    );

    const record = await queryOne<VoiceRecord>('SELECT * FROM voice_records WHERE id = $1', [recordId]);
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
      'SELECT * FROM voice_records WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL',
      [id, userId]
    );

    if (!record) {
      res.status(404).json({ error: 'Voice record not found' });
      return;
    }

    await execute('UPDATE voice_records SET transcription_status = $1 WHERE id = $2', ['processing', id]);

    const transcribeResult = await runPythonTool('voice_process.py', { file: record.file_url });
    let transcript = '转写暂不可用，请稍后重试。';

    if (transcribeResult.success && transcribeResult.data && typeof transcribeResult.data === 'object') {
      const data = transcribeResult.data as { transcript?: string };
      transcript = data.transcript || transcript;
    }

    await execute(
      'UPDATE voice_records SET transcript = $1, transcription_status = $2 WHERE id = $3',
      [transcript, 'completed', id]
    );

    const updatedRecord = await queryOne<VoiceRecord>('SELECT * FROM voice_records WHERE id = $1', [id]);
    res.json({ voice_record: updatedRecord, transcript });
  } catch (error) {
    console.error('Transcribe voice error:', error);
    await execute('UPDATE voice_records SET transcription_status = $1 WHERE id = $2', ['failed', req.params.id]);
    res.status(500).json({ error: 'Failed to transcribe voice' });
  }
});

router.post('/:id/analyze', async (req: AuthenticatedRequest, res: Response) => {
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

    if (!record.allow_ai_analysis) {
      res.status(400).json({ error: 'AI analysis is disabled for this record' });
      return;
    }

    let transcript = record.transcript;
    if (!transcript) {
      const transcribeResult = await runPythonTool('voice_process.py', { file: record.file_url });
      if (transcribeResult.success && transcribeResult.data && typeof transcribeResult.data === 'object') {
        const data = transcribeResult.data as { transcript?: string };
        transcript = data.transcript || '无转写内容';
        await execute(
          'UPDATE voice_records SET transcript = $1, transcription_status = $2 WHERE id = $3',
          [transcript, 'completed', id]
        );
      } else {
        transcript = '无转写内容';
      }
    }

    await execute('UPDATE voice_records SET analysis_status = $1 WHERE id = $2', ['processing', id]);

    const analysis = await analyzeText(transcript);
    await execute(
      `UPDATE voice_records
       SET emotion = $1, emotion_intensity = $2, keywords = $3, ai_summary = $4, risk_level = $5, analysis_status = $6
       WHERE id = $7`,
      [analysis.emotion, analysis.intensity, analysis.keywords, analysis.summary, analysis.risk_level === 'critical' ? 'high' : analysis.risk_level, 'completed', id]
    );

    if (record.write_to_emotion_profile) {
      await createEmotionRecord(userId, analysis, 'voice', id);
    }
    await createRiskEventIfNeeded(userId, analysis, 'voice', id, transcript);

    const updatedRecord = await queryOne<VoiceRecord>('SELECT * FROM voice_records WHERE id = $1', [id]);

    res.json({
      voice_record: updatedRecord,
      emotion: analysis.emotion,
      emotion_intensity: analysis.intensity,
      emotion_analysis: analysis
    });
  } catch (error) {
    console.error('Analyze voice error:', error);
    await execute('UPDATE voice_records SET analysis_status = $1 WHERE id = $2', ['failed', req.params.id]);
    res.status(500).json({ error: 'Failed to analyze voice' });
  }
});

router.delete('/:id', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { id } = req.params;
    const userId = req.user!.id;
    const deleted = await execute(
      'UPDATE voice_records SET deleted_at = $1 WHERE id = $2 AND user_id = $3 AND deleted_at IS NULL',
      [new Date().toISOString(), id, userId]
    );

    if (deleted === 0) {
      res.status(404).json({ error: 'Voice record not found' });
      return;
    }

    res.json({ success: true });
  } catch (error) {
    console.error('Delete voice record error:', error);
    res.status(500).json({ error: 'Failed to delete voice record' });
  }
});

export default router;
