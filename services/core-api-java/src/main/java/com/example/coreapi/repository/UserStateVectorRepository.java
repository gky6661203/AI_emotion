
package com.example.coreapi.repository;

import com.example.coreapi.entity.UserStateVector;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserStateVectorRepository extends JpaRepository<UserStateVector, UUID> {
    Optional<UserStateVector> findByUserId(UUID userId);
    List<UserStateVector> findByUserIdOrderByComputedAtDesc(UUID userId);
}
