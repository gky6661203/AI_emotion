import http from '@ohos.net.http';
import { User, ChatMessage, PrivateLetter, VoiceRecord, Recommendation } from '../models/Types';

const BASE_URL = 'http://localhost:8080';
const TIMEOUT = 30000;

export class ApiService {
  private token: string = '';
  private baseUrl: string = BASE_URL;

  setToken(token: string): void {
    this.token = token;
  }

  getToken(): string {
    return this.token;
  }

  private createHttpRequest(): http.HttpRequest {
    let request = http.createHttpRequest();
    request.method = http.RequestMethod;
    request.connectTimeout = TIMEOUT;
    request.readTimeout = TIMEOUT;
    return request;
  }

  private getHeaders(): Record<string, string> {
    let headers: Record<string, string> = {
      'Content-Type': 'application/json'
    };
    if (this.token) {
      headers['Authorization'] = `Bearer ${this.token}`;
    }
    return headers;
  }

  async request<T>(method: http.RequestMethod, path: string, body?: object): Promise<T> {
    let request = this.createHttpRequest();
    request.url = this.baseUrl + path;
    request.method = method;
    request.header = this.getHeaders();

    let response = await request.request(body ? JSON.stringify(body) : '');
    if (response.responseCode !== 200 && response.responseCode !== 201) {
      throw new Error(`HTTP ${response.responseCode}: ${response.result}`);
    }

    return JSON.parse(response.result as string) as T;
  }

  async healthCheck(): Promise<boolean> {
    try {
      await this.request<{ status: string }>('GET', '/health');
      return true;
    } catch {
      return false;
    }
  }

  async createAnonymous(campus?: string, enrollmentYear?: number): Promise<{ user: User, token: string }> {
    let result = await this.request<{ user: User, token: string }>('POST', '/api/auth/anonymous', {
      campus,
      enrollment_year: enrollmentYear
    });
    this.token = result.token;
    return result;
  }

  async bindDevice(deviceId: string, deviceType?: string, deviceName?: string): Promise<{ device: any }> {
    return this.request<{ device: any }>('POST', '/api/devices/bind', {
      device_id: deviceId,
      device_type: deviceType,
      device_name: deviceName
    });
  }

  async sendMessage(content: string): Promise<{ message: ChatMessage, ai_response?: ChatMessage }> {
    return this.request<{ message: ChatMessage, ai_response?: ChatMessage }>('POST', '/api/chat/messages', {
      content
    });
  }

  async createLetter(content: string, title?: string): Promise<{ letter: PrivateLetter }> {
    return this.request<{ letter: PrivateLetter }>('POST', '/api/private-letters', {
      content,
      title
    });
  }

  async uploadVoiceRecord(fileUrl: string, durationSeconds?: number): Promise<{ voice_record: VoiceRecord }> {
    return this.request<{ voice_record: VoiceRecord }>('POST', '/api/voice-records', {
      file_url: fileUrl,
      duration_seconds: durationSeconds
    });
  }

  async transcribeVoice(recordId: string): Promise<{ voice_record: VoiceRecord, transcript: string }> {
    return this.request<{ voice_record: VoiceRecord, transcript: string }>(
      'POST',
      `/api/voice-records/${recordId}/transcribe`,
      {}
    );
  }

  async analyzeVoice(recordId: string): Promise<{ voice_record: VoiceRecord, emotion: string, emotion_intensity: number }> {
    return this.request<any>('POST', `/api/voice-records/${recordId}/analyze`, {});
  }

  async getRecommendations(limit?: number): Promise<{ recommendations: Recommendation[] }> {
    return this.request<{ recommendations: Recommendation[] }>('GET', `/api/recommendations/current?limit=${limit || 5}`);
  }

  async getEmotionReport(days?: number): Promise<any> {
    return this.request<any>('GET', `/api/emotions/report?days=${days || 7}`);
  }
}

export let apiService = new ApiService();