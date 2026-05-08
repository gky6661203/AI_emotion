
package com.example.coreapi.service;

import com.example.coreapi.dto.response.EmotionReportResponse;
import com.example.coreapi.entity.EmotionRecord;
import com.example.coreapi.entity.User;
import com.example.coreapi.repository.EmotionRecordRepository;
import com.example.coreapi.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class EmotionService {

    private final EmotionRecordRepository emotionRecordRepository;
    private final UserRepository userRepository;

    public EmotionService(EmotionRecordRepository emotionRecordRepository, UserRepository userRepository) {
        this.emotionRecordRepository = emotionRecordRepository;
        this.userRepository = userRepository;
    }

    public EmotionReportResponse getEmotionReport(String token) {
        User user = userRepository.findByAnonymousToken(token)
                .orElseThrow(() -> new RuntimeException("User not found"));

        LocalDateTime end = LocalDateTime.now();
        LocalDateTime start = end.minusDays(7);

        List<EmotionRecord> records = emotionRecordRepository.findByUserIdAndCreatedAtBetweenOrderByCreatedAtDesc(
                user.getId(), start, end);

        EmotionReportResponse report = new EmotionReportResponse();
        report.setPeriod("weekly");
        report.setGeneratedAt(LocalDateTime.now());

        if (records.isEmpty()) {
            report.setDominantEmotion("neutral");
            report.setAverageIntensity(0.5);
            report.setFrequentEmotions(Collections.emptyList());
            report.setEmotionDistribution(Collections.emptyMap());
            report.setRiskAssessment("low");
            report.setRecommendations(Arrays.asList("继续保持良好的心态", "如果有需要，随时可以倾诉"));
            return report;
        }

        Map<String, Long> emotionCounts = records.stream()
                .collect(Collectors.groupingBy(EmotionRecord::getEmotion, Collectors.counting()));

        String dominantEmotion = emotionCounts.entrySet().stream()
                .max(Map.Entry.comparingByValue())
                .map(Map.Entry::getKey)
                .orElse("neutral");

        double avgIntensity = records.stream()
                .mapToDouble(EmotionRecord::getIntensity)
                .average()
                .orElse(0.5);

        List<String> frequentEmotions = emotionCounts.entrySet().stream()
                .sorted(Map.Entry.<String, Long>comparingByValue().reversed())
                .limit(3)
                .map(Map.Entry::getKey)
                .collect(Collectors.toList());

        Map<String, Double> distribution = new HashMap<>();
        emotionCounts.forEach((emotion, count) -> 
            distribution.put(emotion, count.doubleValue() / records.size())
        );

        String riskAssessment = assessRisk(records);
        List<String> recommendations = generateRecommendations(dominantEmotion, riskAssessment);

        report.setDominantEmotion(dominantEmotion);
        report.setAverageIntensity(Math.round(avgIntensity * 100.0) / 100.0);
        report.setFrequentEmotions(frequentEmotions);
        report.setEmotionDistribution(distribution);
        report.setRiskAssessment(riskAssessment);
        report.setRecommendations(recommendations);

        return report;
    }

    private String assessRisk(List<EmotionRecord> records) {
        long highRiskCount = records.stream()
                .filter(EmotionRecord::getRiskDetected)
                .count();
        
        if (highRiskCount > records.size() * 0.3) {
            return "high";
        } else if (highRiskCount > 0) {
            return "medium";
        }
        return "low";
    }

    private List<String> generateRecommendations(String dominantEmotion, String riskAssessment) {
        List<String> recommendations = new ArrayList<>();

        switch (dominantEmotion.toLowerCase()) {
            case "sad":
                recommendations.add("建议与朋友或家人多交流");
                recommendations.add("适当进行户外活动");
                recommendations.add("如果情绪持续低落，建议寻求专业帮助");
                break;
            case "anxious":
            case "stressed":
                recommendations.add("尝试冥想或深呼吸练习");
                recommendations.add("合理安排学习和休息时间");
                recommendations.add("可以尝试听一些舒缓的音乐");
                break;
            case "angry":
                recommendations.add("情绪激动时可以先冷静几分钟");
                recommendations.add("尝试运动释放压力");
                recommendations.add("寻找合适的方式表达情绪");
                break;
            case "happy":
            case "excited":
                recommendations.add("继续保持积极的心态");
                recommendations.add("与他人分享快乐");
                recommendations.add("注意保持平衡的生活节奏");
                break;
            default:
                recommendations.add("保持良好的生活习惯");
                recommendations.add("注意情绪变化，及时调整");
        }

        if ("high".equals(riskAssessment)) {
            recommendations.add("建议尽快联系心理咨询师");
        }

        return recommendations;
    }
}
