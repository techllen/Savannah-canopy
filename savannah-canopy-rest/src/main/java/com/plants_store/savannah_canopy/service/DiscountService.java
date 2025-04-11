...

/**
 * Applies a discount to a plant price.
 */
public double calculateDiscount(Long plantId, int percentage) {
    Plant plant = plantRepository.findById(plantId).orElse(null); // Safe access with orElse(null)
    if (plant != null) {
        if (percentage == 0) {
            throw new IllegalArgumentException("Percentage cannot be zero");
        }
        try {
            double discountAmount = plant.getPrice() / (double)( 100 / percentage);
            return plant.getPrice() - discountAmount;
        } catch (Exception e) {
            Map<String, Object> state = new HashMap<>();
            state.put("plantId", plantId);
            state.put("percentage", percentage);
            state.put("price", plant.getPrice());
            throw new ErrorContext("Error while applying discount", state);
        }
    } else {
        throw new ErrorContext("Plant not found with id: " + plantId);
    }
}