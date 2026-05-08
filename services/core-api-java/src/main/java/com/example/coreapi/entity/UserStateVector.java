
package com.example.coreapi.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "user_state_vectors")
public class UserStateVector {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "dimension_valence")
    private Double dimensionValence = 0.5;

    @Column(name = "dimension_arousal")
    private Double dimensionArousal = 0.5;

    @Column(name = "dimension_dominance")
    private Double dimensionDominance = 0.5;

    @Column(name = "dimension_social")
    private Double dimensionSocial = 0.5;

    @Column(name = "dimension_cognitive")
    private Double dimensionCognitive = 0.5;

    @Column(name = "vector_snapshot", columnDefinition = "JSONB")
    private String vectorSnapshot;

    @Column(name = "computed_at")
    private LocalDateTime computedAt = LocalDateTime.now();

    // Getters and Setters
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public Double getDimensionValence() { return dimensionValence; }
    public void setDimensionValence(Double dimensionValence) { this.dimensionValence = dimensionValence; }

    public Double getDimensionArousal() { return dimensionArousal; }
    public void setDimensionArousal(Double dimensionArousal) { this.dimensionArousal = dimensionArousal; }

    public Double getDimensionDominance() { return dimensionDominance; }
    public void setDimensionDominance(Double dimensionDominance) { this.dimensionDominance = dimensionDominance; }

    public Double getDimensionSocial() { return dimensionSocial; }
    public void setDimensionSocial(Double dimensionSocial) { this.dimensionSocial = dimensionSocial; }

    public Double getDimensionCognitive() { return dimensionCognitive; }
    public void setDimensionCognitive(Double dimensionCognitive) { this.dimensionCognitive = dimensionCognitive; }

    public String getVectorSnapshot() { return vectorSnapshot; }
    public void setVectorSnapshot(String vectorSnapshot) { this.vectorSnapshot = vectorSnapshot; }

    public LocalDateTime getComputedAt() { return computedAt; }
    public void setComputedAt(LocalDateTime computedAt) { this.computedAt = computedAt; }
}
