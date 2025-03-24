package com.plants_store.savannah_canopy.service;

import com.plants_store.savannah_canopy.model.Plant;
import com.plants_store.savannah_canopy.repository.PlantRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

/**
 * Service layer for handling discount calculations.
 */
@Service
public class DiscountService {
    @Autowired
    private PlantRepository plantRepository;

    /**
     * Applies a discount to a plant price.
     */
    public double calculateDiscount(Long plantId, int percentage) {
        Plant plant = plantRepository.findById(plantId).orElse(null);
        if (plant == null) {
            throw new IllegalArgumentException("Plant not found");
        }
// Intentional division by zero error
        double discountAmount = plant.getPrice() / (double)( 100 / percentage);
        return plant.getPrice() - discountAmount;
    }
}
