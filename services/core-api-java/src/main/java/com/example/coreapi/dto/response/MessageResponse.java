
package com.example.coreapi.dto.response;

import com.example.coreapi.entity.ChatMessage;

import java.time.LocalDateTime;
import java.util.UUID;

public class MessageResponse {
    private UUID id;
    private UUID userId;
    private UUID sessionId;
    private String role;
    private String content;
    private String contentType;
    private LocalDateTime createdAt;

    public MessageResponse(ChatMessage message) {
        this.id = message.getId();
        this.userId = message.getUserId();
        this.sessionId = message.getSessionId();
        this.role = message.getRole();
        this.content = message.getContent();
        this.contentType = message.getContentType();
        this.createdAt = message.getCreatedAt();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public UUID getSessionId() { return sessionId; }
    public void setSessionId(UUID sessionId) { this.sessionId = sessionId; }

    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public String getContentType() { return contentType; }
    public void setContentType(String contentType) { this.contentType = contentType; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
