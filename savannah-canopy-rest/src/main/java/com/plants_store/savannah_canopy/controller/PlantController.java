package com.plants_store.savannah_canopy.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.plants_store.savannah_canopy.model.Plant;
import com.plants_store.savannah_canopy.service.PlantService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * REST controller to handle plant-related endpoints.
 */
@RestController
@RequestMapping("/api/plants")
public class PlantController {
    private static final Logger logger = LoggerFactory.getLogger(PaymentController.class);

    @Autowired
    private PlantService plantService;

    @GetMapping("/")
    public List<Plant> getAllPlants() {
//        System.out.println(plantService.getAllPlants());
        logger.info("Plants retreived successfully");
        return plantService.getAllPlants();
    }
}