
package com.example.coreapi.dto.response;

import com.example.coreapi.entity.Device;

import java.time.LocalDateTime;
import java.util.UUID;

public class DeviceResponse {
    private UUID id;
    private String deviceId;
    private String deviceType;
    private String deviceName;
    private String osVersion;
    private String appVersion;
    private LocalDateTime lastSyncAt;
    private Boolean isActive;
    private LocalDateTime createdAt;

    public DeviceResponse(Device device) {
        this.id = device.getId();
        this.deviceId = device.getDeviceId();
        this.deviceType = device.getDeviceType();
        this.deviceName = device.getDeviceName();
        this.osVersion = device.getOsVersion();
        this.appVersion = device.getAppVersion();
        this.lastSyncAt = device.getLastSyncAt();
        this.isActive = device.getIsActive();
        this.createdAt = device.getCreatedAt();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getDeviceId() { return deviceId; }
    public void setDeviceId(String deviceId) { this.deviceId = deviceId; }

    public String getDeviceType() { return deviceType; }
    public void setDeviceType(String deviceType) { this.deviceType = deviceType; }

    public String getDeviceName() { return deviceName; }
    public void setDeviceName(String deviceName) { this.deviceName = deviceName; }

    public String getOsVersion() { return osVersion; }
    public void setOsVersion(String osVersion) { this.osVersion = osVersion; }

    public String getAppVersion() { return appVersion; }
    public void setAppVersion(String appVersion) { this.appVersion = appVersion; }

    public LocalDateTime getLastSyncAt() { return lastSyncAt; }
    public void setLastSyncAt(LocalDateTime lastSyncAt) { this.lastSyncAt = lastSyncAt; }

    public Boolean getIsActive() { return isActive; }
    public void setIsActive(Boolean isActive) { this.isActive = isActive; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
