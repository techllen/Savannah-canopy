package com.plants_store.savannah_canopy.service;

/**
 * Interface defining operations for applying discounts.
 */
public interface DiscountService {

    /**
     * Calculates the discounted price for a given plant and percentage.
     * @param plantId The ID of the plant.
     * @param percentage The discount percentage to apply.
     * @return The calculated price after applying the discount.
     * @throws com.plants_store.savannah_canopy.exception.ErrorContext if the plant is not found or an error occurs during calculation.
     */
    double calculateDiscount(Long plantId, int percentage);

    // Added null check
    default double calculateDiscount(Long plantId, int percentage) {
        if (plantId == null) {
            throw new ErrorContext("PlantId cannot be null.");
        }
        double price = getPrice(plantId); // Assuming getPrice is a method to get the price of a plant
        return price * (1 - percentage / 100.0);
    }
}