//package com.plants_store.savannah_canopy.controller;
//
//import com.store.savannah_canopy.model.User;
//import com.store.savannah_canopy.service.AuthService;
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.web.bind.annotation.PostMapping;
//import org.springframework.web.bind.annotation.RequestBody;
//import org.springframework.web.bind.annotation.RequestMapping;
//import org.springframework.web.bind.annotation.RestController;
//
///**
// * REST controller for authentication.
// */
//@RestController
//@RequestMapping("/api/auth")
//public class AuthController {
//    @Autowired
//    private AuthService authService;
//
//    @PostMapping("/login")
//    public User login(@RequestBody User loginRequest) {
//        return authService.authenticate(loginRequest.getUsername(), loginRequest.getPassword());
//    }
//}
