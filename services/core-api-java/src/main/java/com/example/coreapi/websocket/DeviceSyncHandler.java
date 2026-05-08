
package com.example.coreapi.websocket;

import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class DeviceSyncHandler extends TextWebSocketHandler {

    private final Map<String, WebSocketSession> sessions = new ConcurrentHashMap<>();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        String token = session.getUri().getQuery().split("=")[1];
        sessions.put(token, session);
        session.sendMessage(new TextMessage("{\"type\": \"connected\", \"message\": \"Device sync connected\"}"));
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        String payload = message.getPayload();
        String token = session.getUri().getQuery().split("=")[1];
        
        broadcast(token, payload);
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        String token = session.getUri().getQuery().split("=")[1];
        sessions.remove(token);
    }

    private void broadcast(String token, String message) throws IOException {
        WebSocketSession session = sessions.get(token);
        if (session != null && session.isOpen()) {
            session.sendMessage(new TextMessage(message));
        }
    }
}
