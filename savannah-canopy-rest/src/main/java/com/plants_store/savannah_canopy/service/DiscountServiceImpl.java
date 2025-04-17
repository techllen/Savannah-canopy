package com.plants_store.savannah_canopy.service;

import com.plants_store.savannah_canopy.exception.ErrorContext;
import com.plants_store.savannah_canopy.model.Plant;
import com.plants_store.savannah_canopy.repository.PlantRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.util.ObjectUtils;

/**
 * Service layer implementation for handling discount calculations.
 */
@Service
public class DiscountServiceImpl implements DiscountService {
 // Implement the interface

 @Autowired
 private PlantRepository plantRepository;

 @Override
 public double calculateDiscount(Long plantId, int percentage) {
 Plant plant = plantRepository.findById(plantId).orElse(null);

 if (ObjectUtils.isEmpty(plant)) {
 throw new ErrorContext("Error while applying discount", plantId);
 } 

 if (percentage == 0) {
 throw new IllegalArgumentException("Percentage cannot be zero");
 } 

 double discountAmount = 0.0;

 try {
 discountAmount = plant.getPrice() * (1.0 - (percentage / 100.0));
 } catch (Exception e) {
 Map<String, Object> state = new HashMap<>();
 state.put("plantId", plantId);
 state.put("percentage", percentage);
 state.put("price", plant.getPrice());
 throw new ErrorContext("Error while applying discount", state);
 } 

 return plant.getPrice() - discountAmount;
 }
}