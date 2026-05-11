export interface User {
  id: string;
  anonymous_token?: string;
  email?: string;
  password_hash?: string;
  account_status?: string;
  phone?: string;
  is_anonymous: boolean;
  role: string;
  nickname?: string;
  avatar_url?: string;
  campus?: string;
  enrollment_year?: number;
  risk_level: string;
  state_vector_id?: string;
  total_interactions: number;
  login_failures: number;
  locked_until?: string;
  created_at: string;
  updated_at: string;
  deleted_at?: string;
}

export interface UserStateVector {
  id: string;
  user_id: string;
  dimension_valence: number;
  dimension_arousal: number;
  dimension_dominance: number;
  dimension_social: number;
  dimension_cognitive: number;
  computed_at: string;
}

export interface Device {
  id: string;
  user_id: string;
  device_id: string;
  device_type?: string;
  device_name?: string;
  last_sync_at?: string;
  is_active: boolean;
  created_at: string;
}

export interface ChatMessage {
  id: string;
  user_id: string;
  session_id?: string;
  role: string;
  content: string;
  content_type: string;
  message_metadata?: Record<string, unknown>;
  created_at: string;
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
  affect_recommendation?: Record<string, unknown>;
  affect_matching?: Record<string, unknown>;
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
  voice_features?: Record<string, unknown>;
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
}

export interface EmotionDistributionItem {
  emotion: string;
  count: number;
}

export interface AnonymousProfile {
  id: string;
  user_id: string;
  display_name: string;
  avatar_url?: string;
  bio?: string;
  interests?: string[];
  campus?: string;
  enrollment_year?: number;
  created_at: string;
  updated_at: string;
}

export interface UserPrivacySettings {
  user_id: string;
  allow_chat_analysis: boolean;
  allow_letter_analysis: boolean;
  allow_voice_analysis: boolean;
  allow_profile_update: boolean;
  allow_recommendation_use: boolean;
  allow_match_use: boolean;
  allow_voice_text_retention: boolean;
  allow_multi_device_sync: boolean;
  allow_emotion_reminders: boolean;
  created_at: string;
  updated_at: string;
}

export interface PublicPost {
  id: string;
  user_id: string;
  anonymous_profile_id?: string;
  title?: string;
  content: string;
  topic?: string;
  allow_comments: boolean;
  link_match_request: boolean;
  ai_summary?: string;
  keywords?: string[];
  emotion?: string;
  emotion_intensity?: number;
  risk_level: string;
  moderation_status: string;
  reaction_counts?: Record<string, number>;
  author_display_name?: string;
  author_avatar_url?: string;
  created_at: string;
  updated_at: string;
  deleted_at?: string;
}

export interface PostReaction {
  id: string;
  post_id: string;
  user_id: string;
  reaction_type: string;
  created_at: string;
}

export interface PostReport {
  id: string;
  post_id: string;
  reporter_user_id: string;
  reason: string;
  description?: string;
  status: string;
  created_at: string;
}
export interface EmotionReport {
  user_id: string;
  period_start: string;
  period_end: string;
  dominant_emotion: string;
  average_intensity: number;
  total_records: number;
  risk_events_count: number;
  emotion_distribution: EmotionDistributionItem[];
  recent_records: EmotionRecord[];
}


