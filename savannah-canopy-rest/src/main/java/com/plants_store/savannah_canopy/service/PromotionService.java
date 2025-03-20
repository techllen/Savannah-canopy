package com.plants_store.savannah_canopy.service;

import com.plants_store.savannah_canopy.model.PromotionRequest;
import org.springframework.stereotype.Service;

@Service
public class PromotionService {

    public double calculateDiscountedPrice(PromotionRequest request) {
        double originalPrice = request.getOriginalPrice();
        double discountPercentage = request.getDiscountPercentage();

        // Simulate bad logic (apply discount multiple times)
        double discountedPrice = originalPrice;
        for (int i = 0; i < 3; i++) {
            discountedPrice -= (discountedPrice * (discountPercentage / 100));
        }
        discountedPrice += 10; // Add a fixed amount (incorrect logic)

        return discountedPrice;
    }
}