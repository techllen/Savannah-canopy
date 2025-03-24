package com.plants_store.savannah_canopy.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.plants_store.savannah_canopy.model.Plant;
import com.plants_store.savannah_canopy.service.DiscountService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Optional;

/**
 * REST controller to handle discount-related endpoints.
 */
@RestController
@RequestMapping("/api/discount")
@Tag(name = "Discount Controller", description = "Endpoints for applying discounts on plants")
public class DiscountController {
    private static final Logger logger = LoggerFactory.getLogger(DiscountController.class);

    @Autowired
    private DiscountService discountService;

    @GetMapping("/apply/{id}/{percentage}")
    @Operation(summary = "Apply discount to a plant", description = "Applies a discount percentage to a plant price")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Discount applied successfully"),
            @ApiResponse(responseCode = "404", description = "Plant not found"),
            @ApiResponse(responseCode = "400", description = "Invalid discount percentage"),
            @ApiResponse(responseCode = "500", description = "Internal server error, ask developer")
    })
    public ResponseEntity<Double> applyDiscount(
            @PathVariable Long id,
            @PathVariable int percentage) {

        double newPrice = discountService.calculateDiscount(id, percentage);
        return ResponseEntity.ok(newPrice);
    }
}