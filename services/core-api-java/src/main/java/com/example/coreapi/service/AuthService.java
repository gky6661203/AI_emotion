
package com.example.coreapi.service;

import com.example.coreapi.dto.request.CreateAnonymousUserRequest;
import com.example.coreapi.dto.response.UserResponse;
import com.example.coreapi.entity.User;
import com.example.coreapi.entity.UserStateVector;
import com.example.coreapi.repository.UserRepository;
import com.example.coreapi.repository.UserStateVectorRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final UserStateVectorRepository stateVectorRepository;

    public AuthService(UserRepository userRepository, UserStateVectorRepository stateVectorRepository) {
        this.userRepository = userRepository;
        this.stateVectorRepository = stateVectorRepository;
    }

    @Transactional
    public UserResponse createAnonymousUser(CreateAnonymousUserRequest request) {
        String token = UUID.randomUUID().toString().replace("-", "");
        
        while (userRepository.existsByAnonymousToken(token)) {
            token = UUID.randomUUID().toString().replace("-", "");
        }

        User user = new User();
        user.setAnonymousToken(token);
        user.setNickname(request.getNickname());
        user.setCampus(request.getCampus());
        user.setEnrollmentYear(request.getEnrollmentYear());
        user.setRiskLevel("low");
        user.setTotalInteractions(0);

        User savedUser = userRepository.save(user);

        UserStateVector stateVector = new UserStateVector();
        stateVector.setUserId(savedUser.getId());
        stateVector.setDimensionValence(0.5);
        stateVector.setDimensionArousal(0.5);
        stateVector.setDimensionDominance(0.5);
        stateVector.setDimensionSocial(0.5);
        stateVector.setDimensionCognitive(0.5);

        UserStateVector savedStateVector = stateVectorRepository.save(stateVector);
        
        savedUser.setStateVectorId(savedStateVector.getId());
        userRepository.save(savedUser);

        return new UserResponse(savedUser);
    }

    public UserResponse getUserByToken(String token) {
        return userRepository.findByAnonymousToken(token)
                .map(UserResponse::new)
                .orElseThrow(() -> new RuntimeException("User not found"));
    }
}
