...

/**
 * Applies a discount to a plant price.
 */
public double calculateDiscount(Long plantId, int percentage) {
    Plant plant = plantRepository.findById(plantId).orElse(new Plant()); // Replace null with an empty plant object

    if (plant != null) {
        if (percentage == 0) {
            throw new IllegalArgumentException("Percentage cannot be zero");
        }
        try {
            double discountAmount = plant.getPrice() / (double)( 100 / percentage);
            return plant.getPrice() - discountAmount;
        } catch (Exception e) {
            throw new ErrorContext("Error while applying discount", new HashMap<String, Object>() {{ put("plantId", plantId); put("percentage", percentage); put("price", plant != null ? plant.getPrice() : 0.0); }});
        }
    } else {
        context.getLogger().log("Plant not found with id: " + plantId);
        return plant != null ? plant.getPrice() : 0.0; // Return original price if plant is null
    }
}