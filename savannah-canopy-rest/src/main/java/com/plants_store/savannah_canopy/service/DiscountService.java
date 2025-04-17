package com.plants_store.savannah_canopy.service;

import com.plants_store.savannah_canopy.exception.ErrorContext;

/**
 * Interface defining operations for applying discounts.
 */
public interface DiscountService {

    /**
     * Calculates the discounted price for a given plant and percentage.
     * @param plantId The ID of the plant.
     * @param percentage The discount percentage to apply.
     * @return The calculated price after applying the discount.
     * @throws ErrorContext if the plant is not found or an error occurs during calculation.
     */
    default double calculateDiscount(Long plantId, int percentage) {
        if (percentage < 0 || percentage > 100) {
            throw new IllegalArgumentException("Percentage must be between 0 and 100");
        }
        
        // Retrieve the plant's price (implementation details omitted)
        double price = getPlantPrice(plantId);
        
        // Check if percentage is 0 to avoid division by zero
        if (percentage == 0) {
            return price;
        }
        
        // Calculate the discounted price
        double discountedPrice = price - (price * percentage / 100.0);
        
        return Math.max(0, discountedPrice); // Ensure the price is not negative
    }
    
    // Method to retrieve plant price (to be implemented by concrete classes)
    double getPlantPrice(Long plantId);
}
