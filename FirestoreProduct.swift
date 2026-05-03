//
//  FirestoreProduct.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 15/09/2025.
//

import Foundation
import FirebaseFirestore

struct FirestoreProduct: Codable, Identifiable {
    var id: String?
    let name: String
    let brand: String?
    let category: String
    let barcode: String?
    let store: String
    let price: Double
    let date: Date
    let imageUrl: String?
    let imageStoragePath: String? // Path in Firebase Storage
    let iconName: String?
    let addedBy: String? // User ID who added this product
    let lastUpdated: Date
    
    // Nutritional information
    let nutriscoreGrade: String?
    let nutritionalInfo: NutritionalInfo?
    
    // Ingredient information
    let ingredients: String?
    let allergens: String?
    let traces: String?
    
    // Convert from local Product to FirestoreProduct
    init(from product: Product, addedBy: String? = nil, imageUrl: String? = nil, imageStoragePath: String? = nil) {
        self.id = product.id
        self.name = product.name
        self.brand = product.brand
        self.category = product.category
        self.barcode = product.barcode
        self.store = product.store
        self.price = product.price
        self.date = product.date
        self.imageUrl = imageUrl
        self.imageStoragePath = imageStoragePath
        self.iconName = product.iconName
        self.addedBy = addedBy
        self.lastUpdated = Date()
        self.nutriscoreGrade = product.nutriscoreGrade
        self.nutritionalInfo = product.nutritionalInfo
        self.ingredients = product.ingredients
        self.allergens = product.allergens
        self.traces = product.traces
    }
    
    // Convert to local Product
    func toProduct() -> Product {
        return Product(
            id: id,
            name: name,
            brand: brand,
            category: category,
            barcode: barcode,
            store: store,
            price: price,
            date: date,
            imageData: nil, // We'll handle image data separately
            imageUrl: imageUrl, // Preserve the Firebase Storage URL
            iconName: iconName,
            isChecked: false, // User-specific, not stored in shared DB
            isInShoppingList: false, // User-specific, not stored in shared DB
            nutriscoreGrade: nutriscoreGrade,
            nutritionalInfo: nutritionalInfo,
            ingredients: ingredients,
            allergens: allergens,
            traces: traces
        )
    }
    
    // Custom initializer for creating new products
    init(name: String, brand: String?, category: String, barcode: String?, store: String, price: Double, imageUrl: String? = nil, imageStoragePath: String? = nil, iconName: String? = nil, addedBy: String? = nil, nutriscoreGrade: String? = nil, nutritionalInfo: NutritionalInfo? = nil, ingredients: String? = nil, allergens: String? = nil, traces: String? = nil) {
        self.id = nil // Will be set by Firestore
        self.name = name
        self.brand = brand
        self.category = category
        self.barcode = barcode
        self.store = store
        self.price = price
        self.date = Date()
        self.imageUrl = imageUrl
        self.imageStoragePath = imageStoragePath
        self.iconName = iconName
        self.addedBy = addedBy
        self.lastUpdated = Date()
        self.nutriscoreGrade = nutriscoreGrade
        self.nutritionalInfo = nutritionalInfo
        self.ingredients = ingredients
        self.allergens = allergens
        self.traces = traces
    }
}
