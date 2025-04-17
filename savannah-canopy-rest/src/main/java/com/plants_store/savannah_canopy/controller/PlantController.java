package com.plants_store.savannah_canopy.controller;

import com.plants_store.savannah_canopy.exception.ErrorContext;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.plants_store.savannah_canopy.model.Plant;
import com.plants_store.savannah_canopy.service.PlantService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
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
    private PlantService plantService; // injecting the interface

    @GetMapping("/plant/{id}")
    @Operation(summary = "Get a plant by ID", description = "Retrieves a plant based on its unique identifier")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Successfully retrieved the plant"),
            @ApiResponse(responseCode = "404", description = "Plant not found"),
            @ApiResponse(responseCode = "500", description = "Internal server error, ask developer")
    })
    public ResponseEntity<Plant> getPlant(@PathVariable Long id) {
        Plant plant = plantService.getPlantByID(id);
        logger.info("Plant retrieved successfully");
        return ResponseEntity.ok(plant);
    }

    @GetMapping("/plants")
    @Operation(summary = "Get all plants", description = "Retrieves all plants")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Successfully retrieved the plants"),
            @ApiResponse(responseCode = "404", description = "Plants not found"),
            @ApiResponse(responseCode = "500", description = "Internal server error, ask developer")
    })
    public ResponseEntity<List<Plant>> getAllPlants() {
        List<Plant> plants = plantService.getAllPlants();
        logger.info("Plants retrieved successfully");
        return ResponseEntity.ok(plants);
    }

    @PostMapping("/plants")
    @Operation(summary = "Add a new plant", description = "Saves a new plant in the store")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Plant created successfully"),
            @ApiResponse(responseCode = "400", description = "Invalid plant data"),
            @ApiResponse(responseCode = "500", description = "Internal server error, ask developer")
    })
    public ResponseEntity<Plant> addPlant(@RequestBody Plant plant) {
        Plant savedPlant = plantService.savePlant(plant);
        logger.info("Plant added successfully with ID: {}", savedPlant.getId());
        return ResponseEntity.status(HttpStatus.CREATED).body(savedPlant);
    }
}