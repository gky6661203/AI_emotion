
package com.example.coreapi.dto.response;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public class EmotionReportResponse {
    private String period;
    private String dominantEmotion;
    private Double averageIntensity;
    private List<String> frequentEmotions;
    private Map<String, Double> emotionDistribution;
    private String riskAssessment;
    private List<String> recommendations;
    private LocalDateTime generatedAt;

    public EmotionReportResponse() {}

    public String getPeriod() { return period; }
    public void setPeriod(String period) { this.period = period; }

    public String getDominantEmotion() { return dominantEmotion; }
    public void setDominantEmotion(String dominantEmotion) { this.dominantEmotion = dominantEmotion; }

    public Double getAverageIntensity() { return averageIntensity; }
    public void setAverageIntensity(Double averageIntensity) { this.averageIntensity = averageIntensity; }

    public List<String> getFrequentEmotions() { return frequentEmotions; }
    public void setFrequentEmotions(List<String> frequentEmotions) { this.frequentEmotions = frequentEmotions; }

    public Map<String, Double> getEmotionDistribution() { return emotionDistribution; }
    public void setEmotionDistribution(Map<String, Double> emotionDistribution) { this.emotionDistribution = emotionDistribution; }

    public String getRiskAssessment() { return riskAssessment; }
    public void setRiskAssessment(String riskAssessment) { this.riskAssessment = riskAssessment; }

    public List<String> getRecommendations() { return recommendations; }
    public void setRecommendations(List<String> recommendations) { this.recommendations = recommendations; }

    public LocalDateTime getGeneratedAt() { return generatedAt; }
    public void setGeneratedAt(LocalDateTime generatedAt) { this.generatedAt = generatedAt; }
}
