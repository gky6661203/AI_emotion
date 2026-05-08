
package com.example.coreapi.dto.response;

import java.time.LocalDateTime;
import java.util.List;

public class RecommendationResponse {
    private String type;
    private String title;
    private String description;
    private String contentUrl;
    private Double relevanceScore;
    private LocalDateTime recommendedAt;

    public RecommendationResponse() {}

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getContentUrl() { return contentUrl; }
    public void setContentUrl(String contentUrl) { this.contentUrl = contentUrl; }

    public Double getRelevanceScore() { return relevanceScore; }
    public void setRelevanceScore(Double relevanceScore) { this.relevanceScore = relevanceScore; }

    public LocalDateTime getRecommendedAt() { return recommendedAt; }
    public void setRecommendedAt(LocalDateTime recommendedAt) { this.recommendedAt = recommendedAt; }
}
