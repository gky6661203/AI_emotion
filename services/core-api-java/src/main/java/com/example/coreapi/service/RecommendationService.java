
package com.example.coreapi.service;

import com.example.coreapi.dto.response.RecommendationResponse;
import com.example.coreapi.entity.User;
import com.example.coreapi.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
public class RecommendationService {

    private final UserRepository userRepository;
    private final AiEngineClient aiEngineClient;

    public RecommendationService(UserRepository userRepository, AiEngineClient aiEngineClient) {
        this.userRepository = userRepository;
        this.aiEngineClient = aiEngineClient;
    }

    public List<RecommendationResponse> getCurrentRecommendations(String token) {
        User user = userRepository.findByAnonymousToken(token)
                .orElseThrow(() -> new RuntimeException("User not found"));

        List<RecommendationResponse> recommendations = new ArrayList<>();

        Map<String, Object> aiRecommendation = aiEngineClient.getRecommendations(user.getId().toString());
        
        RecommendationResponse rec = new RecommendationResponse();
        rec.setType((String) aiRecommendation.get("type"));
        rec.setTitle((String) aiRecommendation.get("title"));
        rec.setDescription((String) aiRecommendation.get("description"));
        rec.setContentUrl((String) aiRecommendation.get("content_url"));
        rec.setRelevanceScore((Double) aiRecommendation.get("relevance_score"));
        rec.setRecommendedAt(LocalDateTime.now());

        recommendations.add(rec);

        recommendations.add(createDefaultRecommendation("relaxation", "正念冥想", 
                "每天10分钟正念冥想，帮助放松身心", "https://example.com/mindfulness"));
        recommendations.add(createDefaultRecommendation("resource", "心理支持", 
                "校园心理咨询服务介绍", "https://example.com/counseling"));

        return recommendations;
    }

    private RecommendationResponse createDefaultRecommendation(String type, String title, 
                                                               String description, String url) {
        RecommendationResponse rec = new RecommendationResponse();
        rec.setType(type);
        rec.setTitle(title);
        rec.setDescription(description);
        rec.setContentUrl(url);
        rec.setRelevanceScore(0.75);
        rec.setRecommendedAt(LocalDateTime.now());
        return rec;
    }
}
