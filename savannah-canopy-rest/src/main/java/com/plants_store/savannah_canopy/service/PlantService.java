package com.plants_store.savannah_canopy.service;

import com.plants_store.savannah_canopy.model.Plant;
import java.util.List;

/**
 * Interface defining operations for managing plants.
 */
public interface PlantService {

    /**
     * Retrieves a plant by its unique identifier.
     * @param id The ID of the plant to retrieve.
     * @return The found Plant object.
     * @throws com.plants_store.savannah_canopy.exception.ErrorContext if the plant is not found.
     */
    Plant getPlantByID(long id);

    /**
     * Retrieves all available plants.
     * @return A list of all Plant objects.
     */
    List<Plant> getAllPlants();

    /**
     * Saves a new plant or updates an existing one.
     * @param plant The Plant object to save.
     * @return The saved Plant object, potentially with updated state (like ID).
     */
    Plant savePlant(Plant plant);
}