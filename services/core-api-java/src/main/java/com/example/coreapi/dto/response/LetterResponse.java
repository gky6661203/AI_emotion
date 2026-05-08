
package com.example.coreapi.dto.response;

import com.example.coreapi.entity.PrivateLetter;

import java.time.LocalDateTime;
import java.util.UUID;

public class LetterResponse {
    private UUID id;
    private UUID userId;
    private String title;
    private String content;
    private String contentType;
    private String emotion;
    private Double emotionIntensity;
    private LocalDateTime createdAt;

    public LetterResponse(PrivateLetter letter) {
        this.id = letter.getId();
        this.userId = letter.getUserId();
        this.title = letter.getTitle();
        this.content = letter.getContent();
        this.contentType = letter.getContentType();
        this.emotion = letter.getEmotion();
        this.emotionIntensity = letter.getEmotionIntensity();
        this.createdAt = letter.getCreatedAt();
    }

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

    public String getEmotion() { return emotion; }
    public void setEmotion(String emotion) { this.emotion = emotion; }

    public Double getEmotionIntensity() { return emotionIntensity; }
    public void setEmotionIntensity(Double emotionIntensity) { this.emotionIntensity = emotionIntensity; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
