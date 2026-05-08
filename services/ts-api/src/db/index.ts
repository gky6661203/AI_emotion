import Database from 'better-sqlite3';
import path from 'path';
import dotenv from 'dotenv';

dotenv.config();

const dbPath = process.env.DB_PATH || path.join(__dirname, '../../data/aiemotion.db');

// Ensure data directory exists
import fs from 'fs';
const dbDir = path.dirname(dbPath);
if (!fs.existsSync(dbDir)) {
  fs.mkdirSync(dbDir, { recursive: true });
}

const db = new Database(dbPath);

db.pragma('journal_mode = WAL');

db.on('connect', () => {
  console.log('Connected to SQLite database');
});

export function initDatabase(): void {
  db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      anonymous_token TEXT UNIQUE NOT NULL,
      nickname TEXT,
      avatar_url TEXT,
      campus TEXT,
      enrollment_year INTEGER,
      risk_level TEXT DEFAULT 'low',
      state_vector_id TEXT,
      total_interactions INTEGER DEFAULT 0,
      created_at TEXT,
      updated_at TEXT,
      deleted_at TEXT
    );

    CREATE TABLE IF NOT EXISTS user_state_vectors (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      dimension_valence REAL DEFAULT 0.5,
      dimension_arousal REAL DEFAULT 0.5,
      dimension_dominance REAL DEFAULT 0.5,
      dimension_social REAL DEFAULT 0.5,
      dimension_cognitive REAL DEFAULT 0.5,
      computed_at TEXT
    );

    CREATE TABLE IF NOT EXISTS devices (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      device_id TEXT UNIQUE NOT NULL,
      device_type TEXT,
      device_name TEXT,
      last_sync_at TEXT,
      is_active INTEGER DEFAULT 1,
      created_at TEXT
    );

    CREATE TABLE IF NOT EXISTS chat_messages (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      session_id TEXT,
      role TEXT NOT NULL,
      content TEXT NOT NULL,
      content_type TEXT DEFAULT 'text',
      message_metadata TEXT DEFAULT '{}',
      created_at TEXT
    );

    CREATE TABLE IF NOT EXISTS emotion_records (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      emotion TEXT NOT NULL,
      intensity REAL DEFAULT 0.5,
      source TEXT,
      keywords TEXT,
      ai_summary TEXT,
      risk_detected INTEGER DEFAULT 0,
      created_at TEXT
    );

    CREATE TABLE IF NOT EXISTS private_letters (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      title TEXT,
      content TEXT NOT NULL,
      content_type TEXT DEFAULT 'text',
      allow_ai_analysis INTEGER DEFAULT 1,
      ai_summary TEXT,
      keywords TEXT,
      emotion TEXT,
      emotion_intensity REAL,
      write_to_emotion_profile INTEGER DEFAULT 1,
      is_public INTEGER DEFAULT 0,
      created_at TEXT,
      deleted_at TEXT
    );

    CREATE TABLE IF NOT EXISTS voice_records (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      file_url TEXT NOT NULL,
      duration_seconds INTEGER,
      transcript TEXT,
      emotion TEXT,
      emotion_intensity REAL,
      risk_level TEXT DEFAULT 'low',
      transcription_status TEXT DEFAULT 'pending',
      analysis_status TEXT DEFAULT 'pending',
      allow_ai_analysis INTEGER DEFAULT 1,
      write_to_emotion_profile INTEGER DEFAULT 1,
      created_at TEXT,
      deleted_at TEXT
    );

    CREATE INDEX IF NOT EXISTS idx_users_token ON users(anonymous_token);
    CREATE INDEX IF NOT EXISTS idx_devices_user ON devices(user_id);
    CREATE INDEX IF NOT EXISTS idx_chat_user ON chat_messages(user_id);
    CREATE INDEX IF NOT EXISTS idx_emotion_user ON emotion_records(user_id);
    CREATE INDEX IF NOT EXISTS idx_letters_user ON private_letters(user_id);
    CREATE INDEX IF NOT EXISTS idx_voice_user ON voice_records(user_id);
  `);

  console.log('Database initialized');
}

export function query<T>(sql: string, params?: unknown[]): T[] {
  const stmt = db.prepare(sql);
  const rows = (params ? stmt.all(...params) : stmt.all()) as T[];
  return rows;
}

export function queryOne<T>(sql: string, params?: unknown[]): T | null {
  const stmt = db.prepare(sql);
  const row = (params ? stmt.get(...params) : stmt.get()) as T | undefined;
  return row || null;
}

export function execute(sql: string, params?: unknown[]): number {
  const stmt = db.prepare(sql);
  const result = params ? stmt.run(...params) : stmt.run();
  return result.changes;
}

export default db;
