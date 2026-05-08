import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { initDatabase } from './db';

import authRoutes from './routes/auth';
import devicesRoutes from './routes/devices';
import chatRoutes from './routes/chat';
import lettersRoutes from './routes/letters';
import voiceRoutes from './routes/voice';
import emotionsRoutes from './routes/emotions';
import recommendationsRoutes from './routes/recommendations';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 8080;

app.use(cors());
app.use(express.json());

initDatabase().then(() => {
  app.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
  });

  app.use('/api/auth', authRoutes);
  app.use('/api/devices', devicesRoutes);
  app.use('/api/chat', chatRoutes);
  app.use('/api/private-letters', lettersRoutes);
  app.use('/api/voice-records', voiceRoutes);
  app.use('/api/emotions', emotionsRoutes);
  app.use('/api/recommendations', recommendationsRoutes);

  app.use((err: Error, req: express.Request, res: express.Response, next: express.NextFunction) => {
    console.error('Unhandled error:', err);
    res.status(500).json({ error: 'Internal server error' });
  });

  app.listen(PORT, () => {
    console.log(`TypeScript API server running on port ${PORT}`);
  });
}).catch((error) => {
  console.error('Failed to initialize database:', error);
  process.exit(1);
});
