
package com.example.coreapi.repository;

import com.example.coreapi.entity.EmotionRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface EmotionRecordRepository extends JpaRepository<EmotionRecord, UUID> {
    List<EmotionRecord> findByUserIdOrderByCreatedAtDesc(UUID userId);
    List<EmotionRecord> findByUserIdAndCreatedAtBetweenOrderByCreatedAtDesc(UUID userId, LocalDateTime start, LocalDateTime end);
    List<EmotionRecord> findByRiskDetectedTrue();
}
