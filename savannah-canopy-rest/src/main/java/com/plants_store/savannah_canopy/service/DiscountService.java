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
     * @throws com.plants_store.savannah_canopy.exception.ErrorContext if the plant is not found, the percentage is invalid, or an error occurs during calculation.
     */
    double calculateDiscount(Long plantId, int percentage) throws ErrorContext;

    /**
     * Validates the discount percentage.
     * @param percentage The discount percentage to validate.
     * @throws ErrorContext if the percentage is invalid.
     */
    default void validatePercentage(int percentage) throws ErrorContext {
        if (percentage < 0 || percentage > 100) {
            throw new ErrorContext("Invalid discount percentage", "Percentage must be between 0 and 100", null);
        }
    }
}