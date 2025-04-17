package com.plants_store.savannah_canopy.service;

// Added null check
public interface DiscountService {

    /**
     * Calculates the discounted price for a given plant and percentage.
     * @param plantId The ID of the plant.
     * @param percentage The discount percentage to apply.
     * @return The calculated price after applying the discount.
     * @throws com.plants_store.savannah_canopy.exception.ErrorContext if the plant is not found or an error occurs during calculation.
     */
    double calculateDiscount(Long plantId, int percentage) throws ErrorContext {
        DiscountService discountService = getDiscountService(); // Assuming getDiscountService() method returns the DiscountService instance
        if (discountService != null) {
            return discountService.calculateDiscount(plantId, percentage);
        } else {
            throw new ErrorContext("DiscountService is null");
        }
    }
}