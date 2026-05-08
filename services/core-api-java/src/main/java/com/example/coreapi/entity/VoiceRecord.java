
package com.example.coreapi.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "voice_records")
public class VoiceRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "file_url", nullable = false, length = 500)
    private String fileUrl;

    @Column(name = "file_key", length = 255)
    private String fileKey;

    @Column(name = "duration_seconds")
    private Integer durationSeconds;

    @Column(name = "transcript", columnDefinition = "TEXT")
    private String transcript;

    @Column(name = "emotion", length = 50)
    private String emotion;

    @Column(name = "emotion_intensity")
    private Double emotionIntensity;

    @Column(name = "voice_features", columnDefinition = "JSONB")
    private String voiceFeatures;

    @Column(name = "ai_summary", columnDefinition = "TEXT")
    private String aiSummary;

    @Column(name = "keywords", columnDefinition = "TEXT[]")
    private String[] keywords;

    @Column(name = "risk_level", length = 20)
    private String riskLevel = "low";

    @Column(name = "transcription_status", length = 20)
    private String transcriptionStatus = "pending";

    @Column(name = "analysis_status", length = 20)
    private String analysisStatus = "pending";

    @Column(name = "allow_ai_analysis")
    private Boolean allowAiAnalysis = true;

    @Column(name = "write_to_emotion_profile")
    private Boolean writeToEmotionProfile = true;

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;

    // Getters and Setters
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public String getFileUrl() { return fileUrl; }
    public void setFileUrl(String fileUrl) { this.fileUrl = fileUrl; }

    public String getFileKey() { return fileKey; }
    public void setFileKey(String fileKey) { this.fileKey = fileKey; }

    public Integer getDurationSeconds() { return durationSeconds; }
    public void setDurationSeconds(Integer durationSeconds) { this.durationSeconds = durationSeconds; }

    public String getTranscript() { return transcript; }
    public void setTranscript(String transcript) { this.transcript = transcript; }

    public String getEmotion() { return emotion; }
    public void setEmotion(String emotion) { this.emotion = emotion; }

    public Double getEmotionIntensity() { return emotionIntensity; }
    public void setEmotionIntensity(Double emotionIntensity) { this.emotionIntensity = emotionIntensity; }

    public String getVoiceFeatures() { return voiceFeatures; }
    public void setVoiceFeatures(String voiceFeatures) { this.voiceFeatures = voiceFeatures; }

    public String getAiSummary() { return aiSummary; }
    public void setAiSummary(String aiSummary) { this.aiSummary = aiSummary; }

    public String[] getKeywords() { return keywords; }
    public void setKeywords(String[] keywords) { this.keywords = keywords; }

    public String getRiskLevel() { return riskLevel; }
    public void setRiskLevel(String riskLevel) { this.riskLevel = riskLevel; }

    public String getTranscriptionStatus() { return transcriptionStatus; }
    public void setTranscriptionStatus(String transcriptionStatus) { this.transcriptionStatus = transcriptionStatus; }

    public String getAnalysisStatus() { return analysisStatus; }
    public void setAnalysisStatus(String analysisStatus) { this.analysisStatus = analysisStatus; }

    public Boolean getAllowAiAnalysis() { return allowAiAnalysis; }
    public void setAllowAiAnalysis(Boolean allowAiAnalysis) { this.allowAiAnalysis = allowAiAnalysis; }

    public Boolean getWriteToEmotionProfile() { return writeToEmotionProfile; }
    public void setWriteToEmotionProfile(Boolean writeToEmotionProfile) { this.writeToEmotionProfile = writeToEmotionProfile; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getDeletedAt() { return deletedAt; }
    public void setDeletedAt(LocalDateTime deletedAt) { this.deletedAt = deletedAt; }
}
