//package com.plants_store.savannah_canopy.controller;
//
//import com.store.savannah_canopy.model.Plant;
//import com.store.savannah_canopy.service.PlantService;
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.web.bind.annotation.*;
//
//import java.util.List;
//
///**
// * REST controller to handle plant-related endpoints.
// */
//@RestController
//@RequestMapping("/api/plants")
//public class PlantController {
//    @Autowired
//    private PlantService plantService;
//
//    @GetMapping("/")
//    public List<Plant> getAllPlants() {
//        return plantService.getAllPlants();
//    }
//
//    @PostMapping("/")
//    public Plant addPlant(@RequestBody Plant plant) {
//        return plantService.savePlant(plant);
//    }
//}
