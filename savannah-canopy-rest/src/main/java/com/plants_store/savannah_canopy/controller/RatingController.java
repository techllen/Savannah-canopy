package com.plants_store.savannah_canopy.controller;

import com.plants_store.savannah_canopy.model.RatingRequest;
import com.plants_store.savannah_canopy.service.RatingService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/ratings")
public class RatingController {

    @Autowired
    private RatingService ratingService;

    @Operation(summary = "Submit a plant rating ")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Rating submitted"),
            @ApiResponse(responseCode = "500", description = "Internal server error (division by zero)")
    })
    @PostMapping("/submit")
    public ResponseEntity<Double> submitRating(@RequestBody RatingRequest request) {
        try {
            double averageRating = ratingService.calculateAverageRating(request);
            return ResponseEntity.ok(averageRating);
        } catch (ArithmeticException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
}