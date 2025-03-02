package com.plants_store.savannah_canopy.model;

import jakarta.persistence.*;

/**
 * Entity representing a plant product.
 * Note: The property is named 'imgUrl' which might lead to a mismatch if the UI expects 'imageUrl'. (Intentional mistake #4)
 */
@Entity
@Table(name = "plants")
public class Plant {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;
    private String description;
    private double price;

    // Image URL for the plant product
    private String imageurl;

    @ManyToOne
    @JoinColumn(name = "category_id")
    private Category category;

    // Getters and setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public double getPrice() { return price; }
    public void setPrice(double price) { this.price = price; }

    public String getImgUrl() { return imageurl; }
    public void setImgUrl(String imgUrl) { this.imageurl = imgUrl; }

    public Category getCategory() { return category; }
    public void setCategory(Category category) { this.category = category; }
}
