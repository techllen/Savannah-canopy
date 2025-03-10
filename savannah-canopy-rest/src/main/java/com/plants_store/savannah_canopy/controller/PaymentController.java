package com.plants_store.savannah_canopy.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
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
@CrossOrigin(origins = "http://localhost:3000")
public class PaymentController {

    private static final Logger logger = LoggerFactory.getLogger(PaymentController.class);

    @PostMapping("/checkout")
    public String processPayment(@RequestParam String username, @RequestParam String password) {
        logger.info("Processing payment for user: {}", username); // Sanitize username if needed
        try {
            // ... payment processing logic ...
            logger.info("Payment processed successfully for user: {}", username);
            return "Payment processed for user: " + username;
        } catch (Exception e) {
            logger.error("Error processing payment for user: {}", username, e);
            // ... handle the exception ...
            return "Payment failed";
        }
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> healthCheck() {
        logger.debug("Health check request received");
        Map<String, String> response = new HashMap<>();
        response.put("status", "alive");
        logger.info("Health check successful");
        return ResponseEntity.ok(response);
    }

    @GetMapping("/ErrorPage")
    public ResponseEntity<Map<String, String>> error() {
        logger.error("Error occured");
        Map<String, String> response = new HashMap<>();
        response.put("status", "error");
        logger.info("Check the app, you have a bug");
        return ResponseEntity.ok(response);
    }
}