import { spawn } from 'child_process';
import path from 'path';
import dotenv from 'dotenv';

dotenv.config();

export interface PythonToolResult {
  success: boolean;
  data?: unknown;
  error?: string;
}

export async function runPythonTool(
  scriptName: string,
  args: Record<string, string | number | boolean>
): Promise<PythonToolResult> {
  return new Promise((resolve) => {
    const toolsPath = process.env.PYTHON_TOOLS_PATH || '../python-tools';
    const scriptPath = path.resolve(__dirname, toolsPath, scriptName);

    const pythonArgs: string[] = [];
    Object.entries(args).forEach(([key, value]) => {
      if (typeof value === 'boolean') {
        if (value) pythonArgs.push(`--${key}`);
      } else {
        pythonArgs.push(`--${key}`, String(value));
      }
    });

    const proc = spawn('python', [scriptPath, ...pythonArgs], {
      timeout: 30000,
    });

    let stdout = '';
    let stderr = '';

    proc.stdout.on('data', (data) => {
      stdout += data.toString();
    });

    proc.stderr.on('data', (data) => {
      stderr += data.toString();
    });

    proc.on('close', (code) => {
      if (code === 0) {
        try {
          const result = stdout.trim() ? JSON.parse(stdout.trim()) : {};
          resolve({ success: true, data: result });
        } catch {
          resolve({ success: true, data: stdout.trim() });
        }
      } else {
        console.error(`Python tool ${scriptName} failed:`, stderr);
        resolve({ success: false, error: stderr || `Exit code: ${code}` });
      }
    });

    proc.on('error', (err) => {
      console.error(`Failed to run Python tool ${scriptName}:`, err);
      resolve({ success: false, error: err.message });
    });
  });
}
