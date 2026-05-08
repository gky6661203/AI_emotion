
package com.example.coreapi.controller;

import com.example.coreapi.dto.response.ApiResponse;
import com.example.coreapi.dto.response.EmotionReportResponse;
import com.example.coreapi.service.EmotionService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/emotions")
public class EmotionController {

    private final EmotionService emotionService;

    public EmotionController(EmotionService emotionService) {
        this.emotionService = emotionService;
    }

    @GetMapping("/report")
    public ResponseEntity<ApiResponse<EmotionReportResponse>> getEmotionReport(
            @RequestHeader("X-Anonymous-Token") String token) {
        EmotionReportResponse response = emotionService.getEmotionReport(token);
        return ResponseEntity.ok(ApiResponse.success(response));
    }
}
