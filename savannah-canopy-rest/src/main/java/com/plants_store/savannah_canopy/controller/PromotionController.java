package com.plants_store.savannah_canopy.controller;

import com.plants_store.savannah_canopy.model.PromotionRequest;
import com.plants_store.savannah_canopy.service.PromotionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/promotions")
public class PromotionController {

    @Autowired
    private PromotionService promotionService;

    @Operation(summary = "Apply a promotion ")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Promotion applied"),
            @ApiResponse(responseCode = "500", description = "Internal server error (bad logic)")
    })
    @PostMapping("/apply")
    public ResponseEntity<Double> applyPromotion(@RequestBody PromotionRequest request) {
        try {
            double discountedPrice = promotionService.calculateDiscountedPrice(request);
            return ResponseEntity.ok(discountedPrice);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
}