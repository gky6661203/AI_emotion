
package com.example.coreapi.dto.response;

import com.example.coreapi.entity.User;

import java.time.LocalDateTime;
import java.util.UUID;

public class UserResponse {
    private UUID id;
    private String anonymousToken;
    private String nickname;
    private String campus;
    private Integer enrollmentYear;
    private String riskLevel;
    private LocalDateTime createdAt;

    public UserResponse(User user) {
        this.id = user.getId();
        this.anonymousToken = user.getAnonymousToken();
        this.nickname = user.getNickname();
        this.campus = user.getCampus();
        this.enrollmentYear = user.getEnrollmentYear();
        this.riskLevel = user.getRiskLevel();
        this.createdAt = user.getCreatedAt();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getAnonymousToken() { return anonymousToken; }
    public void setAnonymousToken(String anonymousToken) { this.anonymousToken = anonymousToken; }

    public String getNickname() { return nickname; }
    public void setNickname(String nickname) { this.nickname = nickname; }

    public String getCampus() { return campus; }
    public void setCampus(String campus) { this.campus = campus; }

    public Integer getEnrollmentYear() { return enrollmentYear; }
    public void setEnrollmentYear(Integer enrollmentYear) { this.enrollmentYear = enrollmentYear; }

    public String getRiskLevel() { return riskLevel; }
    public void setRiskLevel(String riskLevel) { this.riskLevel = riskLevel; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
