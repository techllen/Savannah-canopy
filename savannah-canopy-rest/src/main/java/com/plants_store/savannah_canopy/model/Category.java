package com.plants_store.savannah_canopy.model;

import jakarta.persistence.*;

import java.util.List;

/**
 * Entity representing a plant category.
 */
@Entity
@Table(name = "categories")
public class Category {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;

    @OneToMany(mappedBy = "category")
    private List<Plant> plants;

    // Getters and setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public List<Plant> getPlants() { return plants; }
    public void setPlants(List<Plant> plants) { this.plants = plants; }
}
