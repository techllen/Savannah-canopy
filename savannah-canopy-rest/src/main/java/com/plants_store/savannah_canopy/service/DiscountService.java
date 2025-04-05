package com.plants_store.savannah_canopy.service;

import com.plants_store.savannah_canopy.exception.ErrorContext;
import com.plants_store.savannah_canopy.model.Plant;
import com.plants_store.savannah_canopy.repository.PlantRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

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
            throw new ErrorContext("Error while applying discount", plantId);
        }
// Intentional division by zero error
        try {
            double discountAmount = plant.getPrice() / (double)( 100 / percentage);
            return plant.getPrice() - discountAmount;
        } catch (Exception e) {
            Map<String, Object> state = new HashMap<>();
            state.put("plantId", plantId);
            state.put("percentage", percentage);
            state.put("price", plant.getPrice());
            throw new ErrorContext("Error while applying discount", state);
        }
    }
}
