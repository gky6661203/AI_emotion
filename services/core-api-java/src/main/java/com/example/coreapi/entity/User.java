
package com.example.coreapi.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "users")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "anonymous_token", unique = true, nullable = false, length = 255)
    private String anonymousToken;

    @Column(name = "nickname", length = 100)
    private String nickname;

    @Column(name = "avatar_url", length = 500)
    private String avatarUrl;

    @Column(name = "campus", length = 200)
    private String campus;

    @Column(name = "enrollment_year")
    private Integer enrollmentYear;

    @Column(name = "risk_level", length = 20)
    private String riskLevel = "low";

    @Column(name = "state_vector_id")
    private UUID stateVectorId;

    @Column(name = "total_interactions")
    private Integer totalInteractions = 0;

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at")
    private LocalDateTime updatedAt = LocalDateTime.now();

    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;

    // Getters and Setters
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getAnonymousToken() { return anonymousToken; }
    public void setAnonymousToken(String anonymousToken) { this.anonymousToken = anonymousToken; }

    public String getNickname() { return nickname; }
    public void setNickname(String nickname) { this.nickname = nickname; }

    public String getAvatarUrl() { return avatarUrl; }
    public void setAvatarUrl(String avatarUrl) { this.avatarUrl = avatarUrl; }

    public String getCampus() { return campus; }
    public void setCampus(String campus) { this.campus = campus; }

    public Integer getEnrollmentYear() { return enrollmentYear; }
    public void setEnrollmentYear(Integer enrollmentYear) { this.enrollmentYear = enrollmentYear; }

    public String getRiskLevel() { return riskLevel; }
    public void setRiskLevel(String riskLevel) { this.riskLevel = riskLevel; }

    public UUID getStateVectorId() { return stateVectorId; }
    public void setStateVectorId(UUID stateVectorId) { this.stateVectorId = stateVectorId; }

    public Integer getTotalInteractions() { return totalInteractions; }
    public void setTotalInteractions(Integer totalInteractions) { this.totalInteractions = totalInteractions; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

    public LocalDateTime getDeletedAt() { return deletedAt; }
    public void setDeletedAt(LocalDateTime deletedAt) { this.deletedAt = deletedAt; }
}
