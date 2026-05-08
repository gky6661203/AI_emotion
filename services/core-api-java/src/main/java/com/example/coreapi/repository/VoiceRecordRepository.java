
package com.example.coreapi.repository;

import com.example.coreapi.entity.VoiceRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface VoiceRecordRepository extends JpaRepository<VoiceRecord, UUID> {
    List<VoiceRecord> findByUserIdAndDeletedAtIsNullOrderByCreatedAtDesc(UUID userId);
    List<VoiceRecord> findByTranscriptionStatus(String status);
    List<VoiceRecord> findByAnalysisStatus(String status);
}
