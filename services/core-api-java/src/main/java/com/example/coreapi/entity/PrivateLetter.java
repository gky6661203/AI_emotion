
package com.example.coreapi.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "private_letters")
public class PrivateLetter {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "title", length = 200)
    private String title;

    @Column(name = "content", nullable = false, columnDefinition = "TEXT")
    private String content;

    @Column(name = "content_type", length = 20)
    private String contentType = "text";

    @Column(name = "allow_ai_analysis")
    private Boolean allowAiAnalysis = true;

    @Column(name = "ai_summary", columnDefinition = "TEXT")
    private String aiSummary;

    @Column(name = "keywords", columnDefinition = "TEXT[]")
    private String[] keywords;

    @Column(name = "emotion", length = 50)
    private String emotion;

    @Column(name = "emotion_intensity")
    private Double emotionIntensity;

    @Column(name = "write_to_emotion_profile")
    private Boolean writeToEmotionProfile = true;

    @Column(name = "affect_recommendation", columnDefinition = "JSONB")
    private String affectRecommendation;

    @Column(name = "affect_matching", columnDefinition = "JSONB")
    private String affectMatching;

    @Column(name = "open_at")
    private LocalDateTime openAt;

    @Column(name = "is_public")
    private Boolean isPublic = false;

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;

    // Getters and Setters
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public String getContentType() { return contentType; }
    public void setContentType(String contentType) { this.contentType = contentType; }

    public Boolean getAllowAiAnalysis() { return allowAiAnalysis; }
    public void setAllowAiAnalysis(Boolean allowAiAnalysis) { this.allowAiAnalysis = allowAiAnalysis; }

    public String getAiSummary() { return aiSummary; }
    public void setAiSummary(String aiSummary) { this.aiSummary = aiSummary; }

    public String[] getKeywords() { return keywords; }
    public void setKeywords(String[] keywords) { this.keywords = keywords; }

    public String getEmotion() { return emotion; }
    public void setEmotion(String emotion) { this.emotion = emotion; }

    public Double getEmotionIntensity() { return emotionIntensity; }
    public void setEmotionIntensity(Double emotionIntensity) { this.emotionIntensity = emotionIntensity; }

    public Boolean getWriteToEmotionProfile() { return writeToEmotionProfile; }
    public void setWriteToEmotionProfile(Boolean writeToEmotionProfile) { this.writeToEmotionProfile = writeToEmotionProfile; }

    public String getAffectRecommendation() { return affectRecommendation; }
    public void setAffectRecommendation(String affectRecommendation) { this.affectRecommendation = affectRecommendation; }

    public String getAffectMatching() { return affectMatching; }
    public void setAffectMatching(String affectMatching) { this.affectMatching = affectMatching; }

    public LocalDateTime getOpenAt() { return openAt; }
    public void setOpenAt(LocalDateTime openAt) { this.openAt = openAt; }

    public Boolean getIsPublic() { return isPublic; }
    public void setIsPublic(Boolean isPublic) { this.isPublic = isPublic; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getDeletedAt() { return deletedAt; }
    public void setDeletedAt(LocalDateTime deletedAt) { this.deletedAt = deletedAt; }
}
