
package com.example.coreapi.config;

import com.example.coreapi.websocket.DeviceSyncHandler;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

@Configuration
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {

    private final DeviceSyncHandler deviceSyncHandler;

    public WebSocketConfig(DeviceSyncHandler deviceSyncHandler) {
        this.deviceSyncHandler = deviceSyncHandler;
    }

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(deviceSyncHandler, "/ws/devices/sync")
                .setAllowedOrigins("*");
    }
}
