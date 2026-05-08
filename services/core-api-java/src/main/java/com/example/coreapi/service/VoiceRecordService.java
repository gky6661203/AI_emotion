
package com.example.coreapi.service;

import com.example.coreapi.dto.request.UploadVoiceRecordRequest;
import com.example.coreapi.dto.response.VoiceRecordResponse;
import com.example.coreapi.entity.EmotionRecord;
import com.example.coreapi.entity.User;
import com.example.coreapi.entity.VoiceRecord;
import com.example.coreapi.repository.EmotionRecordRepository;
import com.example.coreapi.repository.UserRepository;
import com.example.coreapi.repository.VoiceRecordRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class VoiceRecordService {

    private final VoiceRecordRepository voiceRecordRepository;
    private final UserRepository userRepository;
    private final EmotionRecordRepository emotionRecordRepository;
    private final AiEngineClient aiEngineClient;

    public VoiceRecordService(VoiceRecordRepository voiceRecordRepository,
                              UserRepository userRepository,
                              EmotionRecordRepository emotionRecordRepository,
                              AiEngineClient aiEngineClient) {
        this.voiceRecordRepository = voiceRecordRepository;
        this.userRepository = userRepository;
        this.emotionRecordRepository = emotionRecordRepository;
        this.aiEngineClient = aiEngineClient;
    }

    @Transactional
    public VoiceRecordResponse uploadVoiceRecord(String token, UploadVoiceRecordRequest request) {
        User user = userRepository.findByAnonymousToken(token)
                .orElseThrow(() -> new RuntimeException("User not found"));

        VoiceRecord record = new VoiceRecord();
        record.setUserId(user.getId());
        record.setFileUrl(request.getFileUrl());
        record.setFileKey(request.getFileKey());
        record.setDurationSeconds(request.getDurationSeconds());
        record.setAllowAiAnalysis(request.getAllowAiAnalysis());
        record.setWriteToEmotionProfile(request.getWriteToEmotionProfile());
        record.setTranscriptionStatus("pending");
        record.setAnalysisStatus("pending");

        VoiceRecord savedRecord = voiceRecordRepository.save(record);
        return new VoiceRecordResponse(savedRecord);
    }

    @Transactional
    public VoiceRecordResponse transcribe(String token, UUID recordId) {
        User user = userRepository.findByAnonymousToken(token)
                .orElseThrow(() -> new RuntimeException("User not found"));

        VoiceRecord record = voiceRecordRepository.findById(recordId)
                .filter(r -> r.getUserId().equals(user.getId()))
                .orElseThrow(() -> new RuntimeException("Voice record not found"));

        Map<String, Object> result = aiEngineClient.transcribeVoice(recordId.toString());
        
        record.setTranscript((String) result.get("transcript"));
        record.setTranscriptionStatus("completed");

        VoiceRecord savedRecord = voiceRecordRepository.save(record);
        return new VoiceRecordResponse(savedRecord);
    }

    @Transactional
    public VoiceRecordResponse analyze(String token, UUID recordId) {
        User user = userRepository.findByAnonymousToken(token)
                .orElseThrow(() -> new RuntimeException("User not found"));

        VoiceRecord record = voiceRecordRepository.findById(recordId)
                .filter(r -> r.getUserId().equals(user.getId()))
                .orElseThrow(() -> new RuntimeException("Voice record not found"));

        if ("pending".equals(record.getTranscriptionStatus())) {
            transcribe(token, recordId);
            record = voiceRecordRepository.findById(recordId).orElse(record);
        }

        Map<String, Object> emotionResult = aiEngineClient.analyzeVoice(recordId.toString(), record.getTranscript());
        
        record.setEmotion((String) emotionResult.get("emotion"));
        record.setEmotionIntensity((Double) emotionResult.get("intensity"));
        record.setRiskLevel((String) emotionResult.get("risk_level"));
        record.setAiSummary((String) emotionResult.get("summary"));
        record.setAnalysisStatus("completed");

        if (record.getWriteToEmotionProfile()) {
            EmotionRecord emotionRecord = new EmotionRecord();
            emotionRecord.setUserId(user.getId());
            emotionRecord.setEmotion((String) emotionResult.get("emotion"));
            emotionRecord.setIntensity((Double) emotionResult.get("intensity"));
            emotionRecord.setSource("voice");
            emotionRecord.setSourceId(record.getId());
            emotionRecord.setAiSummary((String) emotionResult.get("summary"));
            
            emotionRecordRepository.save(emotionRecord);
        }

        VoiceRecord savedRecord = voiceRecordRepository.save(record);
        return new VoiceRecordResponse(savedRecord);
    }

    public VoiceRecordResponse getVoiceRecord(String token, UUID recordId) {
        User user = userRepository.findByAnonymousToken(token)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return voiceRecordRepository.findById(recordId)
                .filter(r -> r.getUserId().equals(user.getId()))
                .map(VoiceRecordResponse::new)
                .orElseThrow(() -> new RuntimeException("Voice record not found"));
    }

    public List<VoiceRecordResponse> listVoiceRecords(String token) {
        User user = userRepository.findByAnonymousToken(token)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return voiceRecordRepository.findByUserIdAndDeletedAtIsNullOrderByCreatedAtDesc(user.getId())
                .stream()
                .map(VoiceRecordResponse::new)
                .collect(Collectors.toList());
    }
}
