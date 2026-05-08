
package com.example.coreapi.controller;

import com.example.coreapi.dto.request.CreateLetterRequest;
import com.example.coreapi.dto.response.ApiResponse;
import com.example.coreapi.dto.response.LetterResponse;
import com.example.coreapi.service.LetterService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/private-letters")
public class LetterController {

    private final LetterService letterService;

    public LetterController(LetterService letterService) {
        this.letterService = letterService;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<LetterResponse>> createLetter(
            @RequestHeader("X-Anonymous-Token") String token,
            @RequestBody CreateLetterRequest request) {
        LetterResponse response = letterService.createLetter(token, request);
        return ResponseEntity.ok(ApiResponse.success("Letter created", response));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<LetterResponse>> getLetter(
            @RequestHeader("X-Anonymous-Token") String token,
            @PathVariable UUID id) {
        LetterResponse response = letterService.getLetter(token, id);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<LetterResponse>>> listLetters(
            @RequestHeader("X-Anonymous-Token") String token) {
        List<LetterResponse> response = letterService.listLetters(token);
        return ResponseEntity.ok(ApiResponse.success(response));
    }
}
