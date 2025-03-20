package com.plants_store.savannah_canopy.service;

import com.plants_store.savannah_canopy.model.RatingRequest;
import org.springframework.stereotype.Service;

@Service
public class RatingService {

    public double calculateAverageRating(RatingRequest request) {
        int wateringRating = request.getWateringRating();
        int sunlightRating = request.getSunlightRating();

        // Simulate division by zero if rating factors are incorrect
        return (double) (wateringRating + sunlightRating) / request.getDivisor();
    }
}