//
//  StorePrice.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 18/09/2025.
//

import Foundation

struct StorePrice: Identifiable, Codable, Hashable {
    let id = UUID()
    let store: String
    let price: Double
    let date: Date
    
    init(store: String, price: Double, date: Date = Date()) {
        self.store = store
        self.price = price
        self.date = date
    }
    
    // Conformance to Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: StorePrice, rhs: StorePrice) -> Bool {
        return lhs.id == rhs.id
    }
}

struct ProductWithMultipleStores: Identifiable, Codable, Hashable {
    let id: String // Product identifier (without store)
    let name: String
    let brand: String?
    let category: String
    let barcode: String?
    let imageData: Data?
    let imageUrl: String?
    let iconName: String?
    var isChecked: Bool = false
    var isInShoppingList: Bool = false
    
    // Nutritional information
    let nutriscoreGrade: String?
    let nutritionalInfo: NutritionalInfo?
    
    // Ingredient information
    let ingredients: String?
    let allergens: String?
    let traces: String?
    
    // Store prices
    var storePrices: [StorePrice]
    
    // Computed properties
    var lowestPrice: Double {
        return storePrices.map(\.price).min() ?? 0.0
    }
    
    var cheapestStore: String {
        return storePrices.min(by: { $0.price < $1.price })?.store ?? ""
    }
    
    var sortedStorePrices: [StorePrice] {
        return storePrices.sorted { $0.price < $1.price }
    }
    
    // Custom initializer
    init(id: String? = nil, name: String, brand: String?, category: String, barcode: String?, imageData: Data? = nil, imageUrl: String? = nil, iconName: String? = nil, isChecked: Bool = false, isInShoppingList: Bool = false, nutriscoreGrade: String? = nil, nutritionalInfo: NutritionalInfo? = nil, ingredients: String? = nil, allergens: String? = nil, traces: String? = nil, storePrices: [StorePrice] = []) {
        // Generate stable ID based on product content (without store)
        if let id = id {
            self.id = id
        } else {
            let contentString = "\(name.lowercased())|\(brand?.lowercased() ?? "")|\(category.lowercased())|\(barcode ?? "")"
            self.id = SHA256.hash(data: contentString.data(using: .utf8)!).compactMap { String(format: "%02x", $0) }.joined()
        }
        
        self.name = name
        self.brand = brand
        self.category = category
        self.barcode = barcode
        self.imageData = imageData
        self.imageUrl = imageUrl
        self.iconName = iconName
        self.isChecked = isChecked
        self.isInShoppingList = isInShoppingList
        self.nutriscoreGrade = nutriscoreGrade
        self.nutritionalInfo = nutritionalInfo
        self.ingredients = ingredients
        self.allergens = allergens
        self.traces = traces
        self.storePrices = storePrices
    }
    
    // Add or update store price
    mutating func addOrUpdateStorePrice(store: String, price: Double, date: Date = Date()) {
        if let index = storePrices.firstIndex(where: { $0.store == store }) {
            // Update existing store price
            storePrices[index] = StorePrice(store: store, price: price, date: date)
        } else {
            // Add new store price
            storePrices.append(StorePrice(store: store, price: price, date: date))
        }
    }
    
    // Remove store price
    mutating func removeStorePrice(store: String) {
        storePrices.removeAll { $0.store == store }
    }
    
    // Convert to legacy Product structure (for backward compatibility)
    func toLegacyProduct(preferredStore: String? = nil) -> Product {
        let selectedStore = preferredStore ?? cheapestStore
        let selectedPrice = storePrices.first(where: { $0.store == selectedStore })?.price ?? lowestPrice
        let selectedDate = storePrices.first(where: { $0.store == selectedStore })?.date ?? Date()
        
        return Product(
            id: "\(id)_\(selectedStore)", // Legacy ID format
            name: name,
            brand: brand,
            category: category,
            barcode: barcode,
            store: selectedStore,
            price: selectedPrice,
            date: selectedDate,
            imageData: imageData,
            imageUrl: imageUrl,
            iconName: iconName,
            isChecked: isChecked,
            isInShoppingList: isInShoppingList,
            nutriscoreGrade: nutriscoreGrade,
            nutritionalInfo: nutritionalInfo,
            ingredients: ingredients,
            allergens: allergens,
            traces: traces
        )
    }
    
    // Conformance to Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ProductWithMultipleStores, rhs: ProductWithMultipleStores) -> Bool {
        return lhs.id == rhs.id
    }
}

import CryptoKit // For SHA256 hashing

