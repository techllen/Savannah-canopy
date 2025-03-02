package com.plants_store.savannah_canopy.repository;

import com.plants_store.savannah_canopy.model.Category;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

/**
 * Repository for Category entities.
 */
@Repository
public interface CategoryRepository extends JpaRepository<Category, Long> {
}