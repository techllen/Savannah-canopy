package com.plants_store.savannah_canopy.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.plants_store.savannah_canopy.model.Plant;
import com.plants_store.savannah_canopy.service.PlantService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * REST controller to handle plant-related endpoints.
 */
@RestController
@RequestMapping("/api")
@Tag(name = "Plant Controller", description = "Endpoints for managing plants")
public class PlantController {
    private static final Logger logger = LoggerFactory.getLogger(PlantController.class);

    @Autowired
    private PlantService plantService;

    @GetMapping("/plant/{id}")
    @Operation(summary = "Get a plant by ID", description = "Retrieves a plant based on its unique identifier")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Successfully retrieved the plant"),
            @ApiResponse(responseCode = "404", description = "Plant not found")
    })
    public ResponseEntity<Plant> getPlant(@PathVariable Long id) {
        Plant plant = plantService.getPlantByID(id);
        if (plant == null) {
            logger.info("Plant not found");
            return ResponseEntity.notFound().build();
        }
        logger.info("Plant retrieved successfully");
        return ResponseEntity.ok(plant);
    }

    @GetMapping("/plants")
    @Operation(summary = "Get all plants", description = "Retrieves all plants")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Successfully retrieved the plants"),
            @ApiResponse(responseCode = "404", description = "Plants not found")
    })
    public ResponseEntity<List<Plant>> getAllPlants() {
        List<Plant> plants = plantService.getAllPlants();
        if (plants.isEmpty()) {
            logger.info("No plants found");
            return ResponseEntity.noContent().build();
        }
        logger.info("Plants retrieved successfully");
        return ResponseEntity.ok(plants);
    }
}