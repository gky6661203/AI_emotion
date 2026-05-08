import { Pool } from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgres://postgres:postgres@localhost:5432/aiemotion',
});

export async function initDatabase(): Promise<void> {
  // 数据库表由 SQL 脚本初始化，这里只检查连接
  const client = await pool.connect();
  try {
    await client.query('SELECT 1');
    console.log('Database connected');
  } finally {
    client.release();
  }
}

export async function query<T>(sql: string, params?: unknown[]): Promise<T[]> {
  const result = await pool.query(sql, params);
  return result.rows as T[];
}

export async function queryOne<T>(sql: string, params?: unknown[]): Promise<T | null> {
  const result = await pool.query(sql, params);
  return (result.rows[0] as T) || null;
}

export async function execute(sql: string, params?: unknown[]): Promise<number> {
  const result = await pool.query(sql, params);
  return result.rowCount || 0;
}

export default pool;
