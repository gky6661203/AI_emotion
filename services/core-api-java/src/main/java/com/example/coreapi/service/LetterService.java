
package com.example.coreapi.service;

import com.example.coreapi.dto.request.CreateLetterRequest;
import com.example.coreapi.dto.response.LetterResponse;
import com.example.coreapi.entity.EmotionRecord;
import com.example.coreapi.entity.PrivateLetter;
import com.example.coreapi.entity.User;
import com.example.coreapi.repository.EmotionRecordRepository;
import com.example.coreapi.repository.PrivateLetterRepository;
import com.example.coreapi.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class LetterService {

    private final PrivateLetterRepository privateLetterRepository;
    private final UserRepository userRepository;
    private final EmotionRecordRepository emotionRecordRepository;
    private final AiEngineClient aiEngineClient;

    public LetterService(PrivateLetterRepository privateLetterRepository,
                         UserRepository userRepository,
                         EmotionRecordRepository emotionRecordRepository,
                         AiEngineClient aiEngineClient) {
        this.privateLetterRepository = privateLetterRepository;
        this.userRepository = userRepository;
        this.emotionRecordRepository = emotionRecordRepository;
        this.aiEngineClient = aiEngineClient;
    }

    @Transactional
    public LetterResponse createLetter(String token, CreateLetterRequest request) {
        User user = userRepository.findByAnonymousToken(token)
                .orElseThrow(() -> new RuntimeException("User not found"));

        PrivateLetter letter = new PrivateLetter();
        letter.setUserId(user.getId());
        letter.setTitle(request.getTitle());
        letter.setContent(request.getContent());
        letter.setContentType(request.getContentType());
        letter.setAllowAiAnalysis(request.getAllowAiAnalysis());
        letter.setWriteToEmotionProfile(request.getWriteToEmotionProfile());

        if (request.getAllowAiAnalysis()) {
            Map<String, Object> emotionResult = aiEngineClient.analyzeEmotion(request.getContent());
            letter.setEmotion((String) emotionResult.get("emotion"));
            letter.setEmotionIntensity((Double) emotionResult.get("intensity"));
            letter.setAiSummary((String) emotionResult.get("summary"));
            
            if (request.getWriteToEmotionProfile()) {
                EmotionRecord emotionRecord = new EmotionRecord();
                emotionRecord.setUserId(user.getId());
                emotionRecord.setEmotion((String) emotionResult.get("emotion"));
                emotionRecord.setIntensity((Double) emotionResult.get("intensity"));
                emotionRecord.setSource("text");
                emotionRecord.setAiSummary((String) emotionResult.get("summary"));
                emotionRecord.setTriggerType((String) emotionResult.get("trigger_type"));
                
                emotionRecordRepository.save(emotionRecord);
            }
        }

        PrivateLetter savedLetter = privateLetterRepository.save(letter);
        return new LetterResponse(savedLetter);
    }

    public LetterResponse getLetter(String token, UUID letterId) {
        User user = userRepository.findByAnonymousToken(token)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return privateLetterRepository.findById(letterId)
                .filter(letter -> letter.getUserId().equals(user.getId()))
                .map(LetterResponse::new)
                .orElseThrow(() -> new RuntimeException("Letter not found"));
    }

    public List<LetterResponse> listLetters(String token) {
        User user = userRepository.findByAnonymousToken(token)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return privateLetterRepository.findByUserIdAndDeletedAtIsNullOrderByCreatedAtDesc(user.getId())
                .stream()
                .map(LetterResponse::new)
                .collect(Collectors.toList());
    }
}
