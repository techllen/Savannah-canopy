package com.plants_store.savannah_canopy.service;

import com.plants_store.savannah_canopy.exception.ErrorContext;
import com.plants_store.savannah_canopy.exception.PlantNotFoundException;

/**
 * Interface defining operations for applying discounts.
 */
public interface DiscountService {

    /**
     * Calculates the discounted price for a given plant and percentage.
     * @param plantId The ID of the plant.
     * @param percentage The discount percentage to apply.
     * @return The calculated price after applying the discount.
     * @throws PlantNotFoundException if the plant is not found.
     * @throws ErrorContext if an error occurs during calculation.
     */
    double calculateDiscount(Long plantId, int percentage) throws PlantNotFoundException, ErrorContext;
}
