package com.plants_store.savannah_canopy.repository;

import com.plants_store.savannah_canopy.model.Plant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

/**
 * Repository for Plant entities.
 */
@Repository
public interface PlantRepository extends JpaRepository<Plant, Long> {
}