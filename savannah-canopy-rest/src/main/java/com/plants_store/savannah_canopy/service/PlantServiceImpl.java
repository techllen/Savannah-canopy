package com.plants_store.savannah_canopy.service;

import com.plants_store.savannah_canopy.exception.ErrorContext;
import com.plants_store.savannah_canopy.model.Plant;
import com.plants_store.savannah_canopy.repository.PlantRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Service layer implementation for handling plant-related operations.
 */
@Service
public class PlantServiceImpl implements PlantService { // Implement the interface

    @Autowired
    private PlantRepository plantRepository;

    // Retrieve plant by id
    @Override
    public Plant getPlantByID(long id) {
        Plant plant = plantRepository.findById(id).orElse(null);
        if (plant == null) {
            throw new ErrorContext("Plant cannot be found with id: " + id, id);
        }
        return plant;
    }

    // Retrieve all plants
    @Override
    public List<Plant> getAllPlants() {
        return plantRepository.findAll();
    }

    // Save or update a plant
    @Override
    public Plant savePlant(Plant plant) {
        return plantRepository.save(plant);
    }
}