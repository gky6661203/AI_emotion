
package com.example.coreapi.dto.request;

public class CreateLetterRequest {
    private String title;
    private String content;
    private String contentType = "text";
    private Boolean allowAiAnalysis = true;
    private Boolean writeToEmotionProfile = true;

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public String getContentType() { return contentType; }
    public void setContentType(String contentType) { this.contentType = contentType; }

    public Boolean getAllowAiAnalysis() { return allowAiAnalysis; }
    public void setAllowAiAnalysis(Boolean allowAiAnalysis) { this.allowAiAnalysis = allowAiAnalysis; }

    public Boolean getWriteToEmotionProfile() { return writeToEmotionProfile; }
    public void setWriteToEmotionProfile(Boolean writeToEmotionProfile) { this.writeToEmotionProfile = writeToEmotionProfile; }
}
