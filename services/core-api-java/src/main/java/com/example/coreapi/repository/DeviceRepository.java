
package com.example.coreapi.repository;

import com.example.coreapi.entity.Device;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DeviceRepository extends JpaRepository<Device, UUID> {
    Optional<Device> findByDeviceId(String deviceId);
    List<Device> findByUserIdAndIsActiveTrue(UUID userId);
    boolean existsByDeviceId(String deviceId);
}
