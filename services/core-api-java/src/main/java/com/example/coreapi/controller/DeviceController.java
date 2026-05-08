
package com.example.coreapi.controller;

import com.example.coreapi.dto.request.BindDeviceRequest;
import com.example.coreapi.dto.response.ApiResponse;
import com.example.coreapi.dto.response.DeviceResponse;
import com.example.coreapi.service.DeviceService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/devices")
public class DeviceController {

    private final DeviceService deviceService;

    public DeviceController(DeviceService deviceService) {
        this.deviceService = deviceService;
    }

    @PostMapping("/bind")
    public ResponseEntity<ApiResponse<DeviceResponse>> bindDevice(
            @RequestHeader("X-Anonymous-Token") String token,
            @RequestBody BindDeviceRequest request) {
        DeviceResponse response = deviceService.bindDevice(token, request);
        return ResponseEntity.ok(ApiResponse.success("Device bound", response));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<DeviceResponse>>> listDevices(
            @RequestHeader("X-Anonymous-Token") String token) {
        List<DeviceResponse> response = deviceService.listDevices(token);
        return ResponseEntity.ok(ApiResponse.success(response));
    }
}
