import http from '@ohos.net.http';
import { User, ChatMessage, PrivateLetter, VoiceRecord, Recommendation, EmotionReport } from '../models/Types';

interface Device {
  id: string;
  device_type?: string;
  device_name?: string;
  user_id?: string;
  created_at?: string;
}

interface CreateAnonymousResponse {
  user: User;
  token: string;
}

interface SendMessageResponse {
  message: ChatMessage;
  ai_response?: ChatMessage;
}

interface CreateLetterResponse {
  letter: PrivateLetter;
}

interface BindDeviceResponse {
  device: Device;
}

interface UploadVoiceRecordResponse {
  voice_record: VoiceRecord;
}

interface TranscribeVoiceResponse {
  voice_record: VoiceRecord;
  transcript: string;
}

interface AnalyzeVoiceResponse {
  voice_record: VoiceRecord;
  emotion: string;
  emotion_intensity: number;
}

interface GetRecommendationsResponse {
  recommendations: Recommendation[];
}

interface HttpResponseData {
  responseCode: number;
  result: string | ArrayBuffer | undefined;
}

interface AnonymousRequest {
  campus?: string;
  enrollment_year?: number;
}

interface BindDeviceRequest {
  device_id: string;
  device_type?: string;
  device_name?: string;
}

interface SendMessageRequest {
  content: string;
}

interface CreateLetterRequest {
  content: string;
  title?: string;
}

interface UploadVoiceRequest {
  file_url: string;
  duration_seconds?: number;
}

interface EmptyRequest {
}

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

  private getHeaders(): Record<string, string> {
    let headers: Record<string, string> = {
      'Content-Type': 'application/json'
    };
    if (this.token) {
      headers['Authorization'] = `Bearer ${this.token}`;
    }
    return headers;
  }

  async request<T>(method: string, path: string, body?: object): Promise<T> {
    let httpRequest = http.createHttp();
    let options: http.HttpRequestOptions = {
      method: method as http.RequestMethod,
      header: this.getHeaders(),
      connectTimeout: TIMEOUT,
      readTimeout: TIMEOUT,
      extraData: body ? JSON.stringify(body) : undefined
    };

    let url = this.baseUrl + path;
    let response = await httpRequest.request(url, options);

    let httpResponse = response as HttpResponseData;
    if (httpResponse.responseCode !== 200 && httpResponse.responseCode !== 201) {
      throw new Error(`HTTP ${httpResponse.responseCode}`);
    }

    return JSON.parse(httpResponse.result as string) as T;
  }

  async healthCheck(): Promise<boolean> {
    try {
      await this.request<Record<string, string>>('GET', '/health');
      return true;
    } catch {
      return false;
    }
  }

  async createAnonymous(campus?: string, enrollmentYear?: number): Promise<CreateAnonymousResponse> {
    let body: AnonymousRequest = {
      campus: campus,
      enrollment_year: enrollmentYear
    };
    let result = await this.request<CreateAnonymousResponse>('POST', '/api/auth/anonymous', body);
    this.token = result.token;
    return result;
  }

  async bindDevice(deviceId: string, deviceType?: string, deviceName?: string): Promise<BindDeviceResponse> {
    let body: BindDeviceRequest = {
      device_id: deviceId,
      device_type: deviceType,
      device_name: deviceName
    };
    return this.request<BindDeviceResponse>('POST', '/api/devices/bind', body);
  }

  async sendMessage(content: string): Promise<SendMessageResponse> {
    let body: SendMessageRequest = {
      content: content
    };
    return this.request<SendMessageResponse>('POST', '/api/chat/messages', body);
  }

  async createLetter(content: string, title?: string): Promise<CreateLetterResponse> {
    let body: CreateLetterRequest = {
      content: content,
      title: title
    };
    return this.request<CreateLetterResponse>('POST', '/api/private-letters', body);
  }

  async uploadVoiceRecord(fileUrl: string, durationSeconds?: number): Promise<UploadVoiceRecordResponse> {
    let body: UploadVoiceRequest = {
      file_url: fileUrl,
      duration_seconds: durationSeconds
    };
    return this.request<UploadVoiceRecordResponse>('POST', '/api/voice-records', body);
  }

  async transcribeVoice(recordId: string): Promise<TranscribeVoiceResponse> {
    let body: EmptyRequest = {};
    return this.request<TranscribeVoiceResponse>(
      'POST',
      `/api/voice-records/${recordId}/transcribe`,
      body
    );
  }

  async analyzeVoice(recordId: string): Promise<AnalyzeVoiceResponse> {
    let body: EmptyRequest = {};
    return this.request<AnalyzeVoiceResponse>('POST', `/api/voice-records/${recordId}/analyze`, body);
  }

  async getRecommendations(limit?: number): Promise<GetRecommendationsResponse> {
    return this.request<GetRecommendationsResponse>('GET', `/api/recommendations/current?limit=${limit || 5}`);
  }

  async getEmotionReport(days?: number): Promise<EmotionReport> {
    return this.request<EmotionReport>('GET', `/api/emotions/report?days=${days || 7}`);
  }
}

export let apiService = new ApiService();
