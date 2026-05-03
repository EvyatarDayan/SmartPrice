//
//  Product.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 10/09/2025.
//

import Foundation
import CryptoKit // Import CryptoKit for SHA256 hashing

struct NutritionalInfo: Codable, Hashable {
    let energyKcal: Double?             // Calories
    let fat: Double?                    // Fat
    let saturatedFat: Double?           // Saturated fat
    let sugars: Double?                 // Sugars
    let salt: Double?                   // Salt
    let proteins: Double?               // Proteins
    let carbohydrates: Double?          // Carbohydrates
    let fiber: Double?                  // Fiber
    let nutritionScore: Int?            // Overall nutrition score
    let novaGroup: Int?                 // Processing level
}

struct Product: Identifiable, Codable, Hashable { // Added Hashable conformance
    let id: String // Stable identifier based on product content
    let name: String
    let brand: String?
    let category: String
    let barcode: String?
    let store: String
    let price: Double
    let date: Date
    let imageData: Data?
    let imageUrl: String? // Firebase Storage URL
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
    
    // Custom initializer for creating products with specific values
    init(id: String? = nil, name: String, brand: String?, category: String, barcode: String?, store: String, price: Double, date: Date, imageData: Data?, imageUrl: String? = nil, iconName: String?, isChecked: Bool = false, isInShoppingList: Bool = false, nutriscoreGrade: String? = nil, nutritionalInfo: NutritionalInfo? = nil, ingredients: String? = nil, allergens: String? = nil, traces: String? = nil) {
        // If an ID is provided, use it. Otherwise, generate a stable ID.
        if let id = id {
            self.id = id
        } else {
            // Create a stable ID based on product content
            // Trim whitespace and normalize to ensure consistent IDs
            let normalizedName = name.trimmingCharacters(in: .whitespaces).lowercased()
            let normalizedStore = store.trimmingCharacters(in: .whitespaces).lowercased()
            let normalizedBrand = brand?.trimmingCharacters(in: .whitespaces).lowercased() ?? ""
            let normalizedCategory = category.trimmingCharacters(in: .whitespaces).lowercased()
            let contentString = "\(normalizedName)|\(normalizedStore)|\(normalizedBrand)|\(normalizedCategory)"
            self.id = SHA256.hash(data: contentString.data(using: .utf8)!).compactMap { String(format: "%02x", $0) }.joined()
        }
        
        self.name = name
        self.brand = brand
        self.category = category
        self.barcode = barcode
        self.store = store
        self.price = price
        self.date = date
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
    }
    
    // Conformance to Hashable for stable IDs
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Product, rhs: Product) -> Bool {
        return lhs.id == rhs.id
    }
    
    func formattedPrice(using currencyManager: CurrencyManager) -> String {
        return currencyManager.formatAmount(price)
    }
}

// Sample products for testing
extension Product {
    static let sampleProducts: [Product] = [
        Product(
            name: "Organic Bananas",
            brand: "Fresh Farms",
            category: "Produce",
            barcode: "1234567890",
            store: "ICA",
            price: 25.50,
            date: Date(),
            imageData: nil,
            iconName: "leaf.fill"
        ),
        Product(
            name: "Whole Milk",
            brand: "Arla",
            category: "Dairy",
            barcode: "0987654321",
            store: "Willys",
            price: 18.90,
            date: Date(),
            imageData: nil,
            iconName: "drop.fill"
        ),
        Product(
            name: "Sourdough Bread",
            brand: "Local Bakery",
            category: "Bakery",
            barcode: "1122334455",
            store: "Coop",
            price: 32.00,
            date: Date(),
            imageData: nil,
            iconName: "birthday.cake.fill"
        )
    ]
}