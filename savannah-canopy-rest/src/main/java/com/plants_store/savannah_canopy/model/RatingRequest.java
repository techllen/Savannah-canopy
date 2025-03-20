package com.plants_store.savannah_canopy.model;

public class RatingRequest {
    private int wateringRating;
    private int sunlightRating;
    private int divisor;

    // Getters and setters
    public int getWateringRating() {
        return wateringRating;
    }

    public void setWateringRating(int wateringRating) {
        this.wateringRating = wateringRating;
    }

    public int getSunlightRating() {
        return sunlightRating;
    }

    public void setSunlightRating(int sunlightRating) {
        this.sunlightRating = sunlightRating;
    }

    public int getDivisor() {
        return divisor;
    }

    public void setDivisor(int divisor) {
        this.divisor = divisor;
    }
}