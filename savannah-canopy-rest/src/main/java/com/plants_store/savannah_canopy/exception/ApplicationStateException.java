package com.plants_store.savannah_canopy.exception;

public class ApplicationStateException extends RuntimeException {
    private final Long plantId;
    // add more state variables.

    public ApplicationStateException(String message, Long plantId, Throwable cause) {
        super(message, cause);
        this.plantId = plantId;
    }

    public Long getPlantId() {
        return plantId;
    }
}