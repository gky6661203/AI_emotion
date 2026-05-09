export interface User {
  id: string;
  anonymous_token: string;
  nickname?: string;
  avatar_url?: string;
  campus?: string;
  enrollment_year?: number;
  risk_level: string;
  state_vector_id?: string;
  total_interactions: number;
  created_at: string;
  updated_at: string;
  deleted_at?: string;
}

export interface EmotionAnalysis {
  emotion: string;
  intensity: number;
  keywords: string[];
  response?: string;
  summary: string;
  risk_detected: boolean;
  risk_level: string;
  risk_types: string[];
}

export interface ChatMessage {
  id: string;
  user_id: string;
  session_id?: string;
  role: string;
  content: string;
  content_type: string;
  message_metadata?: object;
  created_at: string;
}

export interface PrivateLetter {
  id: string;
  user_id: string;
  title?: string;
  content: string;
  content_type: string;
  allow_ai_analysis: boolean;
  ai_summary?: string;
  keywords?: string[];
  emotion?: string;
  emotion_intensity?: number;
  write_to_emotion_profile: boolean;
  affect_recommendation?: object;
  affect_matching?: object;
  open_at?: string;
  is_public: boolean;
  created_at: string;
  deleted_at?: string;
}

export interface VoiceRecord {
  id: string;
  user_id: string;
  file_url: string;
  file_key?: string;
  duration_seconds?: number;
  transcript?: string;
  emotion?: string;
  emotion_intensity?: number;
  voice_features?: object;
  ai_summary?: string;
  keywords?: string[];
  risk_level: string;
  transcription_status: string;
  analysis_status: string;
  allow_ai_analysis: boolean;
  write_to_emotion_profile: boolean;
  created_at: string;
  deleted_at?: string;
}

export interface Recommendation {
  recommendation_type: string;
  title: string;
  description?: string;
  priority: number;
  data?: object;
}

export interface EmotionDistributionItem {
  emotion: string;
  count: number;
}

export interface EmotionRecord {
  id: string;
  user_id: string;
  emotion: string;
  intensity: number;
  source: string;
  keywords?: string[];
  risk_detected: boolean;
  created_at: string;
}

export interface EmotionTrendItem {
  date: string;
  average_intensity: number;
  count: number;
  risk_count: number;
}

export interface EmotionReport {
  user_id: string;
  period_start?: string;
  period_end?: string;
  date?: string;
  dominant_emotion: string;
  average_intensity: number;
  total_records: number;
  risk_events_count: number;
  emotion_distribution: EmotionDistributionItem[];
  keywords?: string[];
  summary?: string;
  recent_records: EmotionRecord[];
}

export interface PostsResponse {
  posts: PrivateLetter[];
}

export interface PostResponse {
  post: PrivateLetter;
}

export interface VoiceRecordsResponse {
  voice_records: VoiceRecord[];
}

export interface MessagesResponse {
  messages: ChatMessage[];
}

export interface LettersResponse {
  letters: PrivateLetter[];
}

export interface LetterResponse {
  letter: PrivateLetter;
}

export interface VoiceUploadResponse {
  voice_record: VoiceRecord;
}

export interface TranscribeResponse {
  transcript: string;
  voice_record: VoiceRecord;
}

export interface AnalyzeVoiceResponse {
  emotion: string;
  voice_record: VoiceRecord;
}

export interface TrendsResponse {
  trends: EmotionTrendItem[];
}

export interface SuccessResponse {
  success: boolean;
  message?: string;
}
