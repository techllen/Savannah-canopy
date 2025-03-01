package com.plants_store.savannah_canopy.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * REST controller to simulate payment processing.
 *
 * NOTE: Intentional mistake #5 – The endpoint does not validate authentication properly.
 */
@RestController
@RequestMapping("/api/payment")
@CrossOrigin(origins = "http://localhost:3000") // Allow requests from your React app
public class PaymentController {
    @PostMapping("/checkout")
    public String processPayment(@RequestParam String username, @RequestParam String password) {
        // In a real application, verify authentication and integrate with a payment gateway.
        return "Payment processed for user: " + username;
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> healthCheck() {
        Map<String, String> response = new HashMap<>();
        response.put("status", "alive");
        return ResponseEntity.ok(response);
    }
}