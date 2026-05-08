
package com.example.coreapi.controller;

import com.example.coreapi.dto.request.CreateAnonymousUserRequest;
import com.example.coreapi.dto.response.ApiResponse;
import com.example.coreapi.dto.response.UserResponse;
import com.example.coreapi.service.AuthService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/anonymous")
    public ResponseEntity<ApiResponse<UserResponse>> createAnonymousUser(
            @RequestBody(required = false) CreateAnonymousUserRequest request) {
        if (request == null) {
            request = new CreateAnonymousUserRequest();
        }
        UserResponse response = authService.createAnonymousUser(request);
        return ResponseEntity.ok(ApiResponse.success("User created", response));
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserResponse>> getCurrentUser(
            @RequestHeader("X-Anonymous-Token") String token) {
        UserResponse response = authService.getUserByToken(token);
        return ResponseEntity.ok(ApiResponse.success(response));
    }
}
