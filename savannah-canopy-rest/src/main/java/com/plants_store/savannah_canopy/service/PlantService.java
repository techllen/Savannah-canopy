package com.plants_store.savannah_canopy.service;

import com.plants_store.savannah_canopy.model.Plant;
import com.plants_store.savannah_canopy.repository.PlantRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Service layer for handling plant-related operations.
 */
@Service
public class PlantService {
    @Autowired
    private PlantRepository plantRepository;

    // Retrieve plant by id
    public Plant getPlantByID(long id){
        return  plantRepository.findById(id).orElse(null);
    }

    // Retrieve all plant products
    public List<Plant> getAllPlants() {
        return plantRepository.findAll();
    }

    // Save a plant product
    public Plant savePlant(Plant plant) {
        return plantRepository.save(plant);
    }
}

