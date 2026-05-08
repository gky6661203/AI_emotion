
package com.example.coreapi.dto.response;

import com.example.coreapi.entity.VoiceRecord;

import java.time.LocalDateTime;
import java.util.UUID;

public class VoiceRecordResponse {
    private UUID id;
    private UUID userId;
    private String fileUrl;
    private Integer durationSeconds;
    private String transcript;
    private String emotion;
    private Double emotionIntensity;
    private String riskLevel;
    private String transcriptionStatus;
    private String analysisStatus;
    private LocalDateTime createdAt;

    public VoiceRecordResponse(VoiceRecord record) {
        this.id = record.getId();
        this.userId = record.getUserId();
        this.fileUrl = record.getFileUrl();
        this.durationSeconds = record.getDurationSeconds();
        this.transcript = record.getTranscript();
        this.emotion = record.getEmotion();
        this.emotionIntensity = record.getEmotionIntensity();
        this.riskLevel = record.getRiskLevel();
        this.transcriptionStatus = record.getTranscriptionStatus();
        this.analysisStatus = record.getAnalysisStatus();
        this.createdAt = record.getCreatedAt();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public String getFileUrl() { return fileUrl; }
    public void setFileUrl(String fileUrl) { this.fileUrl = fileUrl; }

    public Integer getDurationSeconds() { return durationSeconds; }
    public void setDurationSeconds(Integer durationSeconds) { this.durationSeconds = durationSeconds; }

    public String getTranscript() { return transcript; }
    public void setTranscript(String transcript) { this.transcript = transcript; }

    public String getEmotion() { return emotion; }
    public void setEmotion(String emotion) { this.emotion = emotion; }

    public Double getEmotionIntensity() { return emotionIntensity; }
    public void setEmotionIntensity(Double emotionIntensity) { this.emotionIntensity = emotionIntensity; }

    public String getRiskLevel() { return riskLevel; }
    public void setRiskLevel(String riskLevel) { this.riskLevel = riskLevel; }

    public String getTranscriptionStatus() { return transcriptionStatus; }
    public void setTranscriptionStatus(String transcriptionStatus) { this.transcriptionStatus = transcriptionStatus; }

    public String getAnalysisStatus() { return analysisStatus; }
    public void setAnalysisStatus(String analysisStatus) { this.analysisStatus = analysisStatus; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
