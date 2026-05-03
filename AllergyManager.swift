//
//  AllergyManager.swift
//  SmartPrice
//
//  Created by AI Assistant on 10/10/2025.
//

import Foundation
import SwiftUI

class AllergyManager: ObservableObject {
    static let shared = AllergyManager()
    
    @Published var userAllergies: Set<String> = []
    @Published var userIngredients: Set<String> = []
    
    private let userDefaults = UserDefaults.standard
    private let allergiesKey = "userAllergies"
    private let ingredientsKey = "userIngredients"
    
    private init() {
        loadAllergies()
    }
    
    // MARK: - Allergy Management
    
    func addAllergy(_ allergy: String) {
        let normalizedAllergy = allergy.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !normalizedAllergy.isEmpty {
            userAllergies.insert(normalizedAllergy)
            saveAllergies()
        }
    }
    
    func removeAllergy(_ allergy: String) {
        let normalizedAllergy = allergy.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        userAllergies.remove(normalizedAllergy)
        saveAllergies()
    }
    
    func addIngredient(_ ingredient: String) {
        let normalizedIngredient = ingredient.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !normalizedIngredient.isEmpty {
            userIngredients.insert(normalizedIngredient)
            saveIngredients()
        }
    }
    
    func removeIngredient(_ ingredient: String) {
        let normalizedIngredient = ingredient.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        userIngredients.remove(normalizedIngredient)
        saveIngredients()
    }
    
    // MARK: - Allergy Detection
    
    /// Checks if a product contains any of the user's allergies or ingredients
    func checkProductForAllergies(_ product: Product) -> AllergyCheckResult {
        var foundAllergies: [String] = []
        var foundIngredients: [String] = []
        
        // Check ingredients text
        if let ingredients = product.ingredients {
            let ingredientsLower = ingredients.lowercased()
            
            for allergy in userAllergies {
                if ingredientsLower.contains(allergy) {
                    foundAllergies.append(allergy)
                }
            }
            
            for ingredient in userIngredients {
                if ingredientsLower.contains(ingredient) {
                    foundIngredients.append(ingredient)
                }
            }
        }
        
        // Check allergens field
        if let allergens = product.allergens {
            let allergensLower = allergens.lowercased()
            
            for allergy in userAllergies {
                if allergensLower.contains(allergy) {
                    foundAllergies.append(allergy)
                }
            }
        }
        
        // Check traces field
        if let traces = product.traces {
            let tracesLower = traces.lowercased()
            
            for allergy in userAllergies {
                if tracesLower.contains(allergy) {
                    foundAllergies.append(allergy)
                }
            }
        }
        
        return AllergyCheckResult(
            hasAllergies: !foundAllergies.isEmpty,
            hasIngredients: !foundIngredients.isEmpty,
            foundAllergies: Array(Set(foundAllergies)), // Remove duplicates
            foundIngredients: Array(Set(foundIngredients)) // Remove duplicates
        )
    }
    
    /// Checks if a ProductWithMultipleStores contains any allergies
    func checkProductForAllergies(_ product: ProductWithMultipleStores) -> AllergyCheckResult {
        // Convert to Product for checking
        let productForCheck = Product(
            id: product.id,
            name: product.name,
            brand: product.brand,
            category: product.category,
            barcode: product.barcode,
            store: product.storePrices.first?.store ?? "",
            price: product.lowestPrice,
            date: Date(),
            imageData: product.imageData,
            imageUrl: product.imageUrl,
            iconName: product.iconName,
            isChecked: false,
            isInShoppingList: false,
            nutriscoreGrade: product.nutriscoreGrade,
            nutritionalInfo: product.nutritionalInfo,
            ingredients: product.ingredients,
            allergens: product.allergens,
            traces: product.traces
        )
        
        return checkProductForAllergies(productForCheck)
    }
    
    // MARK: - Persistence
    
    private func loadAllergies() {
        if let allergiesData = userDefaults.data(forKey: allergiesKey),
           let allergies = try? JSONDecoder().decode(Set<String>.self, from: allergiesData) {
            userAllergies = allergies
        }
        
        if let ingredientsData = userDefaults.data(forKey: ingredientsKey),
           let ingredients = try? JSONDecoder().decode(Set<String>.self, from: ingredientsData) {
            userIngredients = ingredients
        }
    }
    
    private func saveAllergies() {
        if let data = try? JSONEncoder().encode(userAllergies) {
            userDefaults.set(data, forKey: allergiesKey)
        }
    }
    
    private func saveIngredients() {
        if let data = try? JSONEncoder().encode(userIngredients) {
            userDefaults.set(data, forKey: ingredientsKey)
        }
    }
}

// MARK: - Allergy Check Result

struct AllergyCheckResult {
    let hasAllergies: Bool
    let hasIngredients: Bool
    let foundAllergies: [String]
    let foundIngredients: [String]
    
    var hasAnyIssues: Bool {
        return hasAllergies || hasIngredients
    }
    
    var alertMessage: String {
        var messages: [String] = []
        
        if hasAllergies {
            let allergyText = foundAllergies.count == 1 ? "allergy" : "allergies"
            messages.append("⚠️ Contains \(allergyText): \(foundAllergies.joined(separator: ", "))")
        }
        
        if hasIngredients {
            let ingredientText = foundIngredients.count == 1 ? "ingredient" : "ingredients"
            messages.append("⚠️ Contains \(ingredientText): \(foundIngredients.joined(separator: ", "))")
        }
        
        return messages.joined(separator: "\n")
    }
}
