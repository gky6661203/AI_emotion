
package com.example.coreapi.controller;

import com.example.coreapi.dto.response.ApiResponse;
import com.example.coreapi.dto.response.HealthResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {

    @GetMapping("/health")
    public ResponseEntity<ApiResponse<HealthResponse>> healthCheck() {
        HealthResponse response = new HealthResponse("ok", "core-api");
        return ResponseEntity.ok(ApiResponse.success(response));
    }
}
