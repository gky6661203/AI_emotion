
package com.example.coreapi.service;

import com.example.coreapi.dto.request.BindDeviceRequest;
import com.example.coreapi.dto.response.DeviceResponse;
import com.example.coreapi.entity.Device;
import com.example.coreapi.entity.User;
import com.example.coreapi.repository.DeviceRepository;
import com.example.coreapi.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class DeviceService {

    private final DeviceRepository deviceRepository;
    private final UserRepository userRepository;

    public DeviceService(DeviceRepository deviceRepository, UserRepository userRepository) {
        this.deviceRepository = deviceRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public DeviceResponse bindDevice(String token, BindDeviceRequest request) {
        User user = userRepository.findByAnonymousToken(token)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Device device = deviceRepository.findByDeviceId(request.getDeviceId())
                .orElse(new Device());

        device.setUserId(user.getId());
        device.setDeviceId(request.getDeviceId());
        device.setDeviceType(request.getDeviceType());
        device.setDeviceName(request.getDeviceName());
        device.setOsVersion(request.getOsVersion());
        device.setAppVersion(request.getAppVersion());
        device.setIsActive(true);

        Device savedDevice = deviceRepository.save(device);
        return new DeviceResponse(savedDevice);
    }

    public List<DeviceResponse> listDevices(String token) {
        User user = userRepository.findByAnonymousToken(token)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return deviceRepository.findByUserIdAndIsActiveTrue(user.getId())
                .stream()
                .map(DeviceResponse::new)
                .collect(Collectors.toList());
    }
}
