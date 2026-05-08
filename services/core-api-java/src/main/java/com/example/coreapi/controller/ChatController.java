
package com.example.coreapi.controller;

import com.example.coreapi.dto.request.SendMessageRequest;
import com.example.coreapi.dto.response.ApiResponse;
import com.example.coreapi.dto.response.MessageResponse;
import com.example.coreapi.service.ChatService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/chat")
public class ChatController {

    private final ChatService chatService;

    public ChatController(ChatService chatService) {
        this.chatService = chatService;
    }

    @PostMapping("/messages")
    public ResponseEntity<ApiResponse<MessageResponse>> sendMessage(
            @RequestHeader("X-Anonymous-Token") String token,
            @RequestBody SendMessageRequest request) {
        MessageResponse response = chatService.sendMessage(token, request);
        return ResponseEntity.ok(ApiResponse.success("Message sent", response));
    }

    @GetMapping("/messages")
    public ResponseEntity<ApiResponse<List<MessageResponse>>> getMessages(
            @RequestHeader("X-Anonymous-Token") String token) {
        List<MessageResponse> response = chatService.getMessages(token);
        return ResponseEntity.ok(ApiResponse.success(response));
    }
}
