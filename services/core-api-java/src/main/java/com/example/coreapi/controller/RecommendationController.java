
package com.example.coreapi.controller;

import com.example.coreapi.dto.response.ApiResponse;
import com.example.coreapi.dto.response.RecommendationResponse;
import com.example.coreapi.service.RecommendationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/recommendations")
public class RecommendationController {

    private final RecommendationService recommendationService;

    public RecommendationController(RecommendationService recommendationService) {
        this.recommendationService = recommendationService;
    }

    @GetMapping("/current")
    public ResponseEntity<ApiResponse<List<RecommendationResponse>>> getCurrentRecommendations(
            @RequestHeader("X-Anonymous-Token") String token) {
        List<RecommendationResponse> response = recommendationService.getCurrentRecommendations(token);
        return ResponseEntity.ok(ApiResponse.success(response));
    }
}
