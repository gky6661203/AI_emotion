
package com.example.coreapi.dto.request;

public class UploadVoiceRecordRequest {
    private String fileUrl;
    private String fileKey;
    private Integer durationSeconds;
    private Boolean allowAiAnalysis = true;
    private Boolean writeToEmotionProfile = true;

    public String getFileUrl() { return fileUrl; }
    public void setFileUrl(String fileUrl) { this.fileUrl = fileUrl; }

    public String getFileKey() { return fileKey; }
    public void setFileKey(String fileKey) { this.fileKey = fileKey; }

    public Integer getDurationSeconds() { return durationSeconds; }
    public void setDurationSeconds(Integer durationSeconds) { this.durationSeconds = durationSeconds; }

    public Boolean getAllowAiAnalysis() { return allowAiAnalysis; }
    public void setAllowAiAnalysis(Boolean allowAiAnalysis) { this.allowAiAnalysis = allowAiAnalysis; }

    public Boolean getWriteToEmotionProfile() { return writeToEmotionProfile; }
    public void setWriteToEmotionProfile(Boolean writeToEmotionProfile) { this.writeToEmotionProfile = writeToEmotionProfile; }
}
