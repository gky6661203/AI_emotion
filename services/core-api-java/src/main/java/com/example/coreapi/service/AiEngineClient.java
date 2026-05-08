
package com.example.coreapi.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;
import java.util.Random;

@Service
public class AiEngineClient {

    private final RestTemplate restTemplate;
    private final String aiEngineUrl;
    private final Random random = new Random();

    public AiEngineClient(RestTemplate restTemplate, 
                          @Value("${ai.engine.url:http://localhost:8090}") String aiEngineUrl) {
        this.restTemplate = restTemplate;
        this.aiEngineUrl = aiEngineUrl;
    }

    public Map<String, Object> analyzeEmotion(String text) {
        Map<String, Object> result = new HashMap<>();
        String[] emotions = {"happy", "sad", "anxious", "angry", "calm", "excited", "tired", "stressed"};
        String[] triggers = {"study", "relationships", "family", "health", "career", "financial"};
        
        result.put("emotion", emotions[random.nextInt(emotions.length)]);
        result.put("intensity", 0.3 + random.nextDouble() * 0.7);
        result.put("risk_level", "low");
        result.put("summary", "用户表达了情绪状态");
        result.put("keywords", new String[]{"情绪", "感受"});
        result.put("trigger_type", triggers[random.nextInt(triggers.length)]);
        
        return result;
    }

    public Map<String, Object> generateChatResponse(String userMessage) {
        Map<String, Object> result = new HashMap<>();
        
        String[] responses = {
            "我理解你的感受，需要聊聊吗？",
            "谢谢你愿意分享，我在这里陪伴你。",
            "听起来你正在经历一些挑战，我很乐意倾听。",
            "你的感受很重要，让我们一起面对。",
            "我注意到你最近可能有些疲惫，记得照顾好自己。"
        };
        
        result.put("content", responses[random.nextInt(responses.length)]);
        result.put("role", "assistant");
        result.put("emotion", "supportive");
        
        return result;
    }

    public Map<String, Object> transcribeVoice(String voiceId) {
        Map<String, Object> result = new HashMap<>();
        result.put("transcript", "这是语音转写的内容示例。用户表达了他们的情绪和想法。");
        result.put("confidence", 0.95);
        
        return result;
    }

    public Map<String, Object> analyzeVoice(String voiceId, String transcript) {
        return analyzeEmotion(transcript);
    }

    public Map<String, Object> getRecommendations(String userId) {
        Map<String, Object> result = new HashMap<>();
        
        String[][] recommendations = {
            {"relaxation", "冥想音乐", "建议进行冥想放松", "https://example.com/meditation", 0.85},
            {"study", "学习技巧", "提高学习效率的方法", "https://example.com/study", 0.72},
            {"social", "社交活动", "校园活动推荐", "https://example.com/events", 0.68},
            {"exercise", "运动建议", "适合学生的运动方式", "https://example.com/exercise", 0.78},
            {"resource", "心理资源", "心理健康资源", "https://example.com/counseling", 0.90}
        };
        
        int idx = random.nextInt(recommendations.length);
        String[] rec = recommendations[idx];
        
        result.put("type", rec[0]);
        result.put("title", rec[1]);
        result.put("description", rec[2]);
        result.put("content_url", rec[3]);
        result.put("relevance_score", Double.parseDouble(rec[4]));
        
        return result;
    }
}
