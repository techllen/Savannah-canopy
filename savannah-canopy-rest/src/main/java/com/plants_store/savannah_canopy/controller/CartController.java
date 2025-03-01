//package com.plants_store.savannah_canopy.controller;
//
//import com.store.savannah_canopy.model.Cart;
//import com.store.savannah_canopy.model.Plant;
//import com.store.savannah_canopy.model.User;
//import com.store.savannah_canopy.service.AuthService;
//import com.store.savannah_canopy.service.CartService;
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.web.bind.annotation.*;
//
///**
// * REST controller for cart operations.
// */
//@RestController
//@RequestMapping("/api/cart")
//public class CartController {
//    @Autowired
//    private CartService cartService;
//
//    @Autowired
//    private AuthService authService;
//
//    // Endpoint to add a plant to the user's cart.
//    @PostMapping("/add")
//    public Cart addToCart(@RequestParam String username, @RequestParam String password, @RequestBody Plant plant) {
//        User user = authService.authenticate(username, password);
//        if(user == null) {
//            // In production, return a proper error response.
//            return null;
//        }
//        return cartService.addPlantToCart(user, plant);
//    }
//}
