export interface VoiceRecorderResult {
  fileUrl: string;
  durationSeconds: number;
}

export class VoiceRecorder {
  private recording: boolean = false;
  private startedAt: number = 0;
  private currentFileUrl: string = '';

  async start(): Promise<void> {
    this.recording = true;
    this.startedAt = Date.now();
    this.currentFileUrl = `file://temp/voice_${this.startedAt}.m4a`;
  }

  async stop(): Promise<VoiceRecorderResult> {
    if (!this.recording) {
      throw new Error('Recorder is not active');
    }
    this.recording = false;
    const durationSeconds = Math.max(1, Math.round((Date.now() - this.startedAt) / 1000));
    return {
      fileUrl: this.currentFileUrl,
      durationSeconds
    };
  }

  isActive(): boolean {
    return this.recording;
  }
}
