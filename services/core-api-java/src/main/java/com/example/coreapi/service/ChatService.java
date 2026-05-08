
package com.example.coreapi.service;

import com.example.coreapi.dto.request.SendMessageRequest;
import com.example.coreapi.dto.response.MessageResponse;
import com.example.coreapi.entity.ChatMessage;
import com.example.coreapi.entity.EmotionRecord;
import com.example.coreapi.entity.User;
import com.example.coreapi.repository.ChatMessageRepository;
import com.example.coreapi.repository.EmotionRecordRepository;
import com.example.coreapi.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class ChatService {

    private final ChatMessageRepository chatMessageRepository;
    private final UserRepository userRepository;
    private final EmotionRecordRepository emotionRecordRepository;
    private final AiEngineClient aiEngineClient;

    public ChatService(ChatMessageRepository chatMessageRepository,
                       UserRepository userRepository,
                       EmotionRecordRepository emotionRecordRepository,
                       AiEngineClient aiEngineClient) {
        this.chatMessageRepository = chatMessageRepository;
        this.userRepository = userRepository;
        this.emotionRecordRepository = emotionRecordRepository;
        this.aiEngineClient = aiEngineClient;
    }

    @Transactional
    public MessageResponse sendMessage(String token, SendMessageRequest request) {
        User user = userRepository.findByAnonymousToken(token)
                .orElseThrow(() -> new RuntimeException("User not found"));

        ChatMessage userMessage = new ChatMessage();
        userMessage.setUserId(user.getId());
        userMessage.setSessionId(request.getSessionId() != null ? UUID.fromString(request.getSessionId()) : null);
        userMessage.setRole("user");
        userMessage.setContent(request.getContent());
        userMessage.setContentType(request.getContentType());

        ChatMessage savedUserMessage = chatMessageRepository.save(userMessage);

        Map<String, Object> emotionResult = aiEngineClient.analyzeEmotion(request.getContent());
        
        EmotionRecord emotionRecord = new EmotionRecord();
        emotionRecord.setUserId(user.getId());
        emotionRecord.setEmotion((String) emotionResult.get("emotion"));
        emotionRecord.setIntensity((Double) emotionResult.get("intensity"));
        emotionRecord.setSource("text");
        emotionRecord.setSourceId(savedUserMessage.getId());
        emotionRecord.setAiSummary((String) emotionResult.get("summary"));
        emotionRecord.setTriggerType((String) emotionResult.get("trigger_type"));
        emotionRecord.setRiskDetected("high".equals(emotionResult.get("risk_level")));
        
        emotionRecordRepository.save(emotionRecord);

        Map<String, Object> aiResponse = aiEngineClient.generateChatResponse(request.getContent());
        
        ChatMessage aiMessage = new ChatMessage();
        aiMessage.setUserId(user.getId());
        aiMessage.setSessionId(savedUserMessage.getSessionId());
        aiMessage.setRole((String) aiResponse.get("role"));
        aiMessage.setContent((String) aiResponse.get("content"));
        aiMessage.setContentType("text");

        ChatMessage savedAiMessage = chatMessageRepository.save(aiMessage);

        user.setTotalInteractions(user.getTotalInteractions() + 1);
        userRepository.save(user);

        return new MessageResponse(savedAiMessage);
    }

    public List<MessageResponse> getMessages(String token) {
        User user = userRepository.findByAnonymousToken(token)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return chatMessageRepository.findByUserIdOrderByCreatedAtDesc(user.getId())
                .stream()
                .map(MessageResponse::new)
                .collect(Collectors.toList());
    }
}
