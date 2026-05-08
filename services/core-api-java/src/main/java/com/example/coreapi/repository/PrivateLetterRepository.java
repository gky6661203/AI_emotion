
package com.example.coreapi.repository;

import com.example.coreapi.entity.PrivateLetter;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface PrivateLetterRepository extends JpaRepository<PrivateLetter, UUID> {
    List<PrivateLetter> findByUserIdAndDeletedAtIsNullOrderByCreatedAtDesc(UUID userId);
    List<PrivateLetter> findByIsPublicTrueAndDeletedAtIsNullOrderByCreatedAtDesc();
}
