package com.plants_store.savannah_canopy.exception;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.http.ResponseEntity;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.HashMap;
import java.util.Map;

@ControllerAdvice
public class GlobalExceptionHandler {
    private static final Logger logger = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(ApplicationStateException.class)
    public ResponseEntity<Object> handleException(ApplicationStateException ex) {
//        // Log the full stack trace
//        logger.error("An error occurred", ex);
//
//        // Optionally, include additional application state information
//        logger.error("Application state: Plant ID:{}", ex.getPlantId());
//
//        return ResponseEntity.status(500).body("Application Error");
        try {
            // Create structured JSON log
            Map<String, Object> logData = new HashMap<>();
            logData.put("message", "An error occurred");
            logData.put("error", ex.getMessage());
            logData.put("stackTrace", ex.getStackTrace()[0].toString());
            logData.put("plantId", ex.getPlantId());

            // Convert to JSON string
            ObjectMapper objectMapper = new ObjectMapper();
            String jsonLog = objectMapper.writeValueAsString(logData);

            // Log it as a JSON entry
            logger.error(jsonLog);
        } catch (Exception e) {
            logger.error("Failed to log error as JSON", e);
        }

        return ResponseEntity.status(500).body("Application Error");
    }
}

