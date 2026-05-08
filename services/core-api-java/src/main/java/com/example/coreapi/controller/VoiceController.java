
package com.example.coreapi.controller;

import com.example.coreapi.dto.request.UploadVoiceRecordRequest;
import com.example.coreapi.dto.response.ApiResponse;
import com.example.coreapi.dto.response.VoiceRecordResponse;
import com.example.coreapi.service.VoiceRecordService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/voice-records")
public class VoiceController {

    private final VoiceRecordService voiceRecordService;

    public VoiceController(VoiceRecordService voiceRecordService) {
        this.voiceRecordService = voiceRecordService;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<VoiceRecordResponse>> uploadVoiceRecord(
            @RequestHeader("X-Anonymous-Token") String token,
            @RequestBody UploadVoiceRecordRequest request) {
        VoiceRecordResponse response = voiceRecordService.uploadVoiceRecord(token, request);
        return ResponseEntity.ok(ApiResponse.success("Voice record uploaded", response));
    }

    @PostMapping("/{id}/transcribe")
    public ResponseEntity<ApiResponse<VoiceRecordResponse>> transcribe(
            @RequestHeader("X-Anonymous-Token") String token,
            @PathVariable UUID id) {
        VoiceRecordResponse response = voiceRecordService.transcribe(token, id);
        return ResponseEntity.ok(ApiResponse.success("Transcription completed", response));
    }

    @PostMapping("/{id}/analyze")
    public ResponseEntity<ApiResponse<VoiceRecordResponse>> analyze(
            @RequestHeader("X-Anonymous-Token") String token,
            @PathVariable UUID id) {
        VoiceRecordResponse response = voiceRecordService.analyze(token, id);
        return ResponseEntity.ok(ApiResponse.success("Analysis completed", response));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<VoiceRecordResponse>> getVoiceRecord(
            @RequestHeader("X-Anonymous-Token") String token,
            @PathVariable UUID id) {
        VoiceRecordResponse response = voiceRecordService.getVoiceRecord(token, id);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<VoiceRecordResponse>>> listVoiceRecords(
            @RequestHeader("X-Anonymous-Token") String token) {
        List<VoiceRecordResponse> response = voiceRecordService.listVoiceRecords(token);
        return ResponseEntity.ok(ApiResponse.success(response));
    }
}
