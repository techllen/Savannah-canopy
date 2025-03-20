package com.plants_store.savannah_canopy.model;

public class PromotionRequest {
    private double originalPrice;
    private double discountPercentage;

    // Getters and setters
    public double getOriginalPrice() {
        return originalPrice;
    }

    public void setOriginalPrice(double originalPrice) {
        this.originalPrice = originalPrice;
    }

    public double getDiscountPercentage() {
        return discountPercentage;
    }

    public void setDiscountPercentage(double discountPercentage) {
        this.discountPercentage = discountPercentage;
    }
}