
package com.example.coreapi.dto.request;

public class SendMessageRequest {
    private String sessionId;
    private String content;
    private String contentType = "text";

    public String getSessionId() { return sessionId; }
    public void setSessionId(String sessionId) { this.sessionId = sessionId; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public String getContentType() { return contentType; }
    public void setContentType(String contentType) { this.contentType = contentType; }
}
