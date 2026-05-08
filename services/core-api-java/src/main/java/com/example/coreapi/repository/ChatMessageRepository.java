
package com.example.coreapi.repository;

import com.example.coreapi.entity.ChatMessage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ChatMessageRepository extends JpaRepository<ChatMessage, UUID> {
    List<ChatMessage> findByUserIdOrderByCreatedAtDesc(UUID userId);
    List<ChatMessage> findBySessionIdOrderByCreatedAtDesc(UUID sessionId);
}
