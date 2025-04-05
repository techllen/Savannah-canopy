package com.plants_store.savannah_canopy.exception;

public class ErrorContext extends RuntimeException {
//    private final Long plantId;
//    // add more state variables.
//
//    public ErrorContext(String message, Long plantId, Throwable cause) {
//        super(message, cause);
//        this.plantId = plantId;
//    }
//
//    public Long getPlantId() {
//        return plantId;
//    }

//    private final Long plantId;
    // add more state variables.
    private final Object applicationState;

    public ErrorContext(String message, Object applicationState) {
        super(message);
        this.applicationState = applicationState;
    }

    public Object getApplicationState() {
        return applicationState;
    }
}