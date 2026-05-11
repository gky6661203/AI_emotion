import http from '@ohos.net.http';
import { User, ChatMessage, PrivateLetter, VoiceRecord, Recommendation, EmotionReport, EmotionTrendItem, EmotionAnalysis, PostsResponse, PostResponse, SuccessResponse, AnonymousProfile, UserPrivacySettings } from '../models/Types';

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

interface AuthResponse {
  user: User;
  token: string;
}

interface AnonymousProfileResponse {
  profile: AnonymousProfile;
}

interface PrivacySettingsResponse {
  settings: UserPrivacySettings;
}

interface MeResponse {
  user: User;
}

interface SendMessageResponse {
  message: ChatMessage;
  ai_response?: ChatMessage;
  emotion_analysis?: EmotionAnalysis;
}

interface SafetyResourceItem {
  title: string;
  description?: string;
  url?: string;
}

interface SafetyResourcesResponse {
  resources?: SafetyResourceItem[];
  message?: string;
}

interface ProfilePreferenceSignals {
  prefersDirectAdvice: boolean;
  prefersVoice: boolean;
  prefersPrivateWriting: boolean;
  openToPublicInteraction: boolean;
  safetySensitive: boolean;
}

interface ProfileStateVector {
  valence: number;
  arousal: number;
  dominance: number;
  social: number;
  cognitive: number;
}

interface ProfileCounts {
  emotion_records: number;
  posts: number;
  letters: number;
  voices: number;
}

interface TimelineStateVector {
  valence: number;
  arousal: number;
  dominance: number;
  social: number;
  cognitive: number;
}

interface TimelineCounts {
  emotion_records: number;
  posts: number;
  letters: number;
  voices: number;
}

interface ProfileTimelineItem {
  snapshot_date?: string;
  dominant_emotion: string;
  average_intensity: number;
  risk_rate: number;
  signal_summary: string;
  state_vector: TimelineStateVector;
  counts: TimelineCounts;
  created_at?: string;
}

interface ProfileTimelineResponse {
  timeline: ProfileTimelineItem[];
}

interface RecommendationFeedbackItem {
  recommendation_type: string;
  title?: string;
  feedback: string;
  rating?: number;
  context?: string;
  created_at: string;
}

interface RecommendationFeedbackResponse {
  success: boolean;
  feedback_id?: string;
}

interface MatchSuggestionItem {
  user_id: string;
  dominant_emotion: string;
  signal_summary: string;
  score: number;
  reason: string;
}

interface ProfileOverviewResponse {
  user_id: string;
  dominant_emotion: string;
  average_intensity: number;
  risk_rate: number;
  signal_summary: string;
  preferred_day?: string;
  preference_signals: ProfilePreferenceSignals;
  state_vector: ProfileStateVector;
  counts: ProfileCounts;
  risk_count?: number;
}

interface MatchSuggestionsResponse {
  suggestions: MatchSuggestionItem[];
  profile?: ProfileOverviewResponse;
}

interface MatchRequestResponse {
  success: boolean;
  request_id?: string;
}

interface MatchRequestItem {
  id: string;
  match_type: string;
  note?: string;
  status: string;
  created_at: string;
}

interface MatchRequestListResponse {
  requests: MatchRequestItem[];
}

interface MessagesResponse {
  messages: ChatMessage[];
}

interface LetterResponse {
  letter: PrivateLetter;
  emotion_analysis?: EmotionAnalysis;
}

interface LettersResponse {
  letters: PrivateLetter[];
}

interface BindDeviceResponse {
  device: Device;
}

interface UploadVoiceRecordResponse {
  voice_record: VoiceRecord;
}

interface VoiceRecordsResponse {
  voice_records: VoiceRecord[];
}

interface TranscribeVoiceResponse {
  voice_record: VoiceRecord;
  transcript: string;
}

interface AnalyzeVoiceResponse {
  voice_record: VoiceRecord;
  emotion: string;
  emotion_intensity: number;
  emotion_analysis?: EmotionAnalysis;
}

interface GetRecommendationsResponse {
  recommendations: Recommendation[];
  dominant_emotion?: string;
  average_intensity?: number;
  risk_level?: string;
}

interface ProfileHighlights {
  active_content_count: number;
  risk_count: number;
  allow_comment_posts: number;
  voice_allowed_count: number;
  letter_profile_write_count: number;
}

interface TrendsResponse {
  trends: EmotionTrendItem[];
}

interface HttpResponseData {
  responseCode: number;
  result: string | ArrayBuffer | undefined;
}


interface AnonymousRequest {
  campus?: string;
  enrollment_year?: number;
}

interface RegisterRequest {
  account: string;
  password: string;
  nickname?: string;
  campus?: string;
  enrollment_year?: number;
}

interface LoginRequest {
  account: string;
  password: string;
}

interface UpdateAnonymousProfileRequest {
  display_name?: string;
  avatar_url?: string;
  bio?: string;
  interests?: string[];
  campus?: string;
  enrollment_year?: number;
}

interface UpdatePrivacySettingsRequest {
  allow_chat_analysis?: boolean;
  allow_letter_analysis?: boolean;
  allow_voice_analysis?: boolean;
  allow_profile_update?: boolean;
  allow_recommendation_use?: boolean;
  allow_match_use?: boolean;
  allow_voice_text_retention?: boolean;
  allow_multi_device_sync?: boolean;
  allow_emotion_reminders?: boolean;
}

interface BindDeviceRequest {
  device_id: string;
  device_type?: string;
  device_name?: string;
}

interface SendMessageRequest {
  content: string;
}

interface SaveLetterRequest {
  content: string;
  title?: string;
  allow_ai_analysis?: boolean;
  write_to_emotion_profile?: boolean;
  open_at?: string;
}

interface UploadVoiceRequest {
  file_url: string;
  duration_seconds?: number;
  allow_ai_analysis?: boolean;
  write_to_emotion_profile?: boolean;
}

interface EmptyRequest {
}

interface CreatePostRequest {
  content: string;
  title?: string;
  allow_comments?: boolean;
}

interface AddReactionRequest {
  type: string;
}

interface ReportPostRequest {
  reason: string;
  description?: string;
}

interface ReportPostResponse {
  success: boolean;
}

interface CommentItem {
  id: string;
  post_id: string;
  user_id: string;
  content: string;
  created_at: string;
  deleted_at?: string;
}

interface CommentsResponse {
  comments: CommentItem[];
}

interface CreateCommentBody {
  content: string;
}

interface CreateCommentResponse {
  comment: CommentItem;
}

interface CreateProfileSnapshotResponse {
  success: boolean;
  snapshot: ProfileOverviewResponse;
}

interface RecommendationFeedbackBody {
  recommendation_type: string;
  title?: string;
  feedback: string;
  rating?: number;
  context?: string;
}

interface MatchRequestBody {
  match_type: string;
  note?: string;
}

interface CloseMatchRequestBody {
  request_id: string;
}

const DEFAULT_BASE_URL = 'http://172.26.48.1:8080';
const TIMEOUT = 30000;
const AUTH_TOKEN_KEY = 'aiemotion_auth_token';

export class ApiService {
  private token: string = '';
  private baseUrl: string = DEFAULT_BASE_URL;

  setToken(token: string): void {
    this.token = token;
    try {
      AppStorage.SetOrCreate(AUTH_TOKEN_KEY, token);
    } catch (err) {
      console.error('persist token failed', err);
    }
  }

  getToken(): string {
    if (!this.token) {
      try {
        let stored = AppStorage.Get<string>(AUTH_TOKEN_KEY);
        if (typeof stored === 'string') {
          this.token = stored;
        }
      } catch (err) {
        console.error('load token failed', err);
      }
    }
    return this.token;
  }

  setBaseUrl(baseUrl: string): void {
    let value = baseUrl.trim();
    if (!value) {
      this.baseUrl = DEFAULT_BASE_URL;
      return;
    }
    this.baseUrl = value.replace(/\/$/, '');
  }

  getBaseUrl(): string {
    return this.baseUrl;
  }

  async ensureAnonymousUser(): Promise<User> {
    if (this.getToken()) {
      try {
        let me = await this.getMe();
        return me.user;
      } catch {
        this.setToken('');
      }
    }
    let created = await this.createAnonymous();
    return created.user;
  }

  private getHeaders(): Record<string, string> {
    let headers: Record<string, string> = {
      'Content-Type': 'application/json'
    };
    let token = this.getToken();
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
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
      let detail = '';
      try {
        let parsed = JSON.parse(httpResponse.result as string) as Record<string, string>;
        detail = parsed.error || parsed.detail || '';
      } catch {
        detail = httpResponse.result as string || '';
      }
      throw new Error(detail || `HTTP ${httpResponse.responseCode}`);
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
    this.setToken(result.token);
    return result;
  }

  async getMe(): Promise<MeResponse> {
    return this.request<MeResponse>('GET', '/api/auth/me');
  }

  async register(account: string, password: string, nickname?: string, campus?: string, enrollmentYear?: number): Promise<AuthResponse> {
    let body: RegisterRequest = { account: account, password: password, nickname: nickname, campus: campus, enrollment_year: enrollmentYear };
    let result = await this.request<AuthResponse>('POST', '/api/auth/register', body);
    this.setToken(result.token);
    return result;
  }

  async login(account: string, password: string): Promise<AuthResponse> {
    let body: LoginRequest = { account: account, password: password };
    let result = await this.request<AuthResponse>('POST', '/api/auth/login', body);
    this.setToken(result.token);
    return result;
  }

  async getAnonymousProfile(): Promise<AnonymousProfileResponse> {
    return this.request<AnonymousProfileResponse>('GET', '/api/anonymous-profile');
  }

  async updateAnonymousProfile(displayName: string, bio?: string, campus?: string): Promise<AnonymousProfileResponse> {
    let body: UpdateAnonymousProfileRequest = { display_name: displayName, bio: bio, campus: campus };
    return this.request<AnonymousProfileResponse>('PATCH', '/api/anonymous-profile', body);
  }

  async randomizeAnonymousProfile(): Promise<AnonymousProfileResponse> {
    let body: EmptyRequest = {};
    return this.request<AnonymousProfileResponse>('POST', '/api/anonymous-profile/randomize', body);
  }

  async getPrivacySettings(): Promise<PrivacySettingsResponse> {
    return this.request<PrivacySettingsResponse>('GET', '/api/privacy-settings');
  }

  async updatePrivacySettings(settings: UpdatePrivacySettingsRequest): Promise<PrivacySettingsResponse> {
    return this.request<PrivacySettingsResponse>('PATCH', '/api/privacy-settings', settings);
  }
  async logout(): Promise<SuccessResponse> {
    let body: EmptyRequest = {};
    let result = await this.request<SuccessResponse>('POST', '/api/auth/logout', body);
    this.token = '';
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

  async listMessages(limit?: number): Promise<MessagesResponse> {
    return this.request<MessagesResponse>('GET', `/api/chat/messages?limit=${limit || 50}`);
  }

  async sendMessage(content: string): Promise<SendMessageResponse> {
    let body: SendMessageRequest = {
      content: content
    };
    return this.request<SendMessageResponse>('POST', '/api/chat/messages', body);
  }

  async getSafetyResources(): Promise<SafetyResourcesResponse> {
    return this.request<SafetyResourcesResponse>('GET', '/api/safety/resources');
  }

  async listLetters(keyword?: string, emotion?: string): Promise<LettersResponse> {
    let params: string[] = [];
    if (keyword) params.push(`keyword=${encodeURIComponent(keyword)}`);
    if (emotion) params.push(`emotion=${encodeURIComponent(emotion)}`);
    let query = params.length > 0 ? `?${params.join('&')}` : '';
    return this.request<LettersResponse>('GET', `/api/private-letters${query}`);
  }

  async createLetter(content: string, title?: string, allowAiAnalysis?: boolean, writeToProfile?: boolean): Promise<LetterResponse> {
    let body: SaveLetterRequest = {
      content: content,
      title: title,
      allow_ai_analysis: allowAiAnalysis,
      write_to_emotion_profile: writeToProfile
    };
    return this.request<LetterResponse>('POST', '/api/private-letters', body);
  }

  async updateLetter(id: string, content: string, title?: string, allowAiAnalysis?: boolean, writeToProfile?: boolean): Promise<LetterResponse> {
    let body: SaveLetterRequest = {
      content: content,
      title: title,
      allow_ai_analysis: allowAiAnalysis,
      write_to_emotion_profile: writeToProfile
    };
    return this.request<LetterResponse>('PATCH', `/api/private-letters/${id}`, body);
  }

  async deleteLetter(id: string): Promise<SuccessResponse> {
    return this.request<SuccessResponse>('DELETE', `/api/private-letters/${id}`);
  }

  async uploadVoiceRecord(fileUrl: string, durationSeconds?: number): Promise<UploadVoiceRecordResponse> {
    let body: UploadVoiceRequest = {
      file_url: fileUrl,
      duration_seconds: durationSeconds,
      allow_ai_analysis: true,
      write_to_emotion_profile: true
    };
    return this.request<UploadVoiceRecordResponse>('POST', '/api/voice-records', body);
  }

  async listVoiceRecords(limit?: number): Promise<VoiceRecordsResponse> {
    return this.request<VoiceRecordsResponse>('GET', `/api/voice-records?limit=${limit || 50}`);
  }

  async transcribeVoice(recordId: string): Promise<TranscribeVoiceResponse> {
    let body: EmptyRequest = {};
    return this.request<TranscribeVoiceResponse>('POST', `/api/voice-records/${recordId}/transcribe`, body);
  }

  async analyzeVoice(recordId: string): Promise<AnalyzeVoiceResponse> {
    let body: EmptyRequest = {};
    return this.request<AnalyzeVoiceResponse>('POST', `/api/voice-records/${recordId}/analyze`, body);
  }

  async deleteVoiceRecord(recordId: string): Promise<SuccessResponse> {
    return this.request<SuccessResponse>('DELETE', `/api/voice-records/${recordId}`);
  }

  async getRecommendations(limit?: number): Promise<GetRecommendationsResponse> {
    return this.request<GetRecommendationsResponse>('GET', `/api/recommendations/current?limit=${limit || 5}`);
  }

  async getProfileOverview(): Promise<ProfileOverviewResponse> {
    return this.request<ProfileOverviewResponse>('GET', '/api/profile/overview');
  }

  async createProfileSnapshot(): Promise<CreateProfileSnapshotResponse> {
    return this.request<CreateProfileSnapshotResponse>('POST', '/api/profile/snapshot');
  }

  async getProfileTimeline(days?: number): Promise<ProfileTimelineResponse> {
    return this.request<ProfileTimelineResponse>('GET', `/api/profile/timeline?days=${days || 14}`);
  }

  async sendRecommendationFeedback(recommendationType: string, feedback: string, title?: string, rating?: number, context?: string): Promise<RecommendationFeedbackResponse> {
    let body: RecommendationFeedbackBody = {
      recommendation_type: recommendationType,
      title: title,
      feedback: feedback,
      rating: rating,
      context: context
    };
    return this.request<RecommendationFeedbackResponse>('POST', '/api/recommendations/feedback', body);
  }

  async getMatchSuggestions(limit?: number): Promise<MatchSuggestionsResponse> {
    return this.request<MatchSuggestionsResponse>('GET', `/api/match/suggestions?limit=${limit || 5}`);
  }

  async createMatchRequest(matchType: string, note?: string): Promise<MatchRequestResponse> {
    let body: MatchRequestBody = { match_type: matchType, note: note };
    return this.request<MatchRequestResponse>('POST', '/api/match/request', body);
  }

  async closeMatchRequest(requestId: string): Promise<SuccessResponse> {
    let body: CloseMatchRequestBody = { request_id: requestId };
    return this.request<SuccessResponse>('POST', '/api/match/close', body);
  }

  async listMatchRequests(): Promise<MatchRequestListResponse> {
    return this.request<MatchRequestListResponse>('GET', '/api/match/requests');
  }

  async getTodayEmotion(): Promise<EmotionReport> {
    return this.request<EmotionReport>('GET', '/api/emotions/today');
  }

  async getEmotionTrends(days?: number): Promise<TrendsResponse> {
    return this.request<TrendsResponse>('GET', `/api/emotions/trends?days=${days || 7}`);
  }

  async getEmotionReport(days?: number): Promise<EmotionReport> {
    return this.request<EmotionReport>('GET', `/api/emotions/report?days=${days || 7}`);
  }

  // --- Plaza Posts ---
  async listPosts(limit?: number): Promise<PostsResponse> {
    return this.request<PostsResponse>('GET', `/api/posts?limit=${limit || 50}`);
  }

  async createPost(content: string, title?: string, allowComments: boolean = true): Promise<PostResponse> {
    let body: CreatePostRequest = {
      content: content,
      title: title,
      allow_comments: allowComments
    };
    await this.ensureAnonymousUser();
    return this.request<PostResponse>('POST', '/api/posts', body);
  }

  async addReaction(postId: string, type: string): Promise<SuccessResponse> {
    let body: AddReactionRequest = {
      type: type
    };
    await this.ensureAnonymousUser();
    return this.request<SuccessResponse>('POST', `/api/posts/${postId}/reactions`, body);
  }

  async deletePost(postId: string): Promise<SuccessResponse> {
    return this.request<SuccessResponse>('DELETE', `/api/posts/${postId}`);
  }

  async reportPost(postId: string, reason: string, description?: string): Promise<ReportPostResponse> {
    let body: ReportPostRequest = {
      reason: reason,
      description: description
    };
    await this.ensureAnonymousUser();
    return this.request<ReportPostResponse>('POST', `/api/posts/${postId}/report`, body);
  }

  async listComments(postId: string): Promise<CommentsResponse> {
    await this.ensureAnonymousUser();
    return this.request<CommentsResponse>('GET', `/api/posts/${postId}/comments`);
  }

  async createComment(postId: string, content: string): Promise<CreateCommentResponse> {
    let body: CreateCommentBody = { content: content };
    return this.request<CreateCommentResponse>('POST', `/api/posts/${postId}/comments`, body);
  }

  async deleteComment(postId: string, commentId: string): Promise<SuccessResponse> {
    return this.request<SuccessResponse>('DELETE', `/api/posts/${postId}/comments/${commentId}`);
  }
}

export let apiService = new ApiService();

