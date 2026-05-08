
package com.example.coreapi.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "emotion_records")
public class EmotionRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "emotion", nullable = false, length = 50)
    private String emotion;

    @Column(name = "intensity")
    private Double intensity = 0.5;

    @Column(name = "source", length = 20)
    private String source;

    @Column(name = "source_id")
    private UUID sourceId;

    @Column(name = "keywords", columnDefinition = "TEXT[]")
    private String[] keywords;

    @Column(name = "ai_summary", columnDefinition = "TEXT")
    private String aiSummary;

    @Column(name = "trigger_type", length = 50)
    private String triggerType;

    @Column(name = "risk_detected")
    private Boolean riskDetected = false;

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();

    // Getters and Setters
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public String getEmotion() { return emotion; }
    public void setEmotion(String emotion) { this.emotion = emotion; }

    public Double getIntensity() { return intensity; }
    public void setIntensity(Double intensity) { this.intensity = intensity; }

    public String getSource() { return source; }
    public void setSource(String source) { this.source = source; }

    public UUID getSourceId() { return sourceId; }
    public void setSourceId(UUID sourceId) { this.sourceId = sourceId; }

    public String[] getKeywords() { return keywords; }
    public void setKeywords(String[] keywords) { this.keywords = keywords; }

    public String getAiSummary() { return aiSummary; }
    public void setAiSummary(String aiSummary) { this.aiSummary = aiSummary; }

    public String getTriggerType() { return triggerType; }
    public void setTriggerType(String triggerType) { this.triggerType = triggerType; }

    public Boolean getRiskDetected() { return riskDetected; }
    public void setRiskDetected(Boolean riskDetected) { this.riskDetected = riskDetected; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
