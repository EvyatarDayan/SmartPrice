//
//  SharedProductDatabase.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 10/09/2025.
//

import Foundation
import SwiftUI

class SharedProductDatabase: ObservableObject {
    static let shared = SharedProductDatabase()
    
    @Published var products: [Product] = []
    
    private let userDefaults = UserDefaults.standard
    private let productsKey = "sharedProducts"
    
    private init() {
        loadProducts()
    }
    
    // MARK: - Product Management
    
    func addProduct(_ product: Product) {
        // Check if product with same name and store already exists
        if let existingIndex = products.firstIndex(where: { 
            $0.name.lowercased() == product.name.lowercased() && 
            $0.store.lowercased() == product.store.lowercased() 
        }) {
            // Update existing product with new price and date (no user-specific data)
            products[existingIndex] = Product(
                name: product.name,
                brand: product.brand,
                category: product.category,
                barcode: product.barcode,
                store: product.store,
                price: product.price,
                date: Date(), // Update to current date
                imageData: product.imageData,
                imageUrl: product.imageUrl,
                iconName: product.iconName,
                isChecked: false, // Always false in shared database
                isInShoppingList: false, // Always false in shared database
                nutriscoreGrade: product.nutriscoreGrade,
                nutritionalInfo: product.nutritionalInfo
            )
        } else {
            // Add new product with current date (no user-specific data)
            let newProduct = Product(
                name: product.name,
                brand: product.brand,
                category: product.category,
                barcode: product.barcode,
                store: product.store,
                price: product.price,
                date: Date(),
                imageData: product.imageData,
                imageUrl: product.imageUrl,
                iconName: product.iconName,
                isChecked: false, // Always false in shared database
                isInShoppingList: false, // Always false in shared database
                nutriscoreGrade: product.nutriscoreGrade,
                nutritionalInfo: product.nutritionalInfo
            )
            products.append(newProduct)
        }
        
        saveProducts()
    }
    
    func updateProduct(_ updatedProduct: Product) {
        if let index = products.firstIndex(where: { $0.id == updatedProduct.id }) {
            products[index] = updatedProduct
            saveProducts()
        }
    }
    
    func deleteProduct(_ product: Product) {
        products.removeAll { $0.id == product.id }
        saveProducts()
    }
    
    // MARK: - Product Search and Filtering
    
    func getProduct(by id: String) -> Product? {
        return products.first { $0.id == id }
    }
    
    // MARK: - Data Persistence
    
    private func saveProducts() {
        if let encoded = try? JSONEncoder().encode(products) {
            userDefaults.set(encoded, forKey: productsKey)
        }
    }
    
    private func loadProducts() {
        if let data = userDefaults.data(forKey: productsKey),
           let decoded = try? JSONDecoder().decode([Product].self, from: data) {
            products = decoded
        } else {
            // Load sample products if no data exists
            products = Product.sampleProducts
            saveProducts()
        }
    }
    
    // MARK: - Helper Methods
    
    func searchProducts(query: String) -> [Product] {
        if query.isEmpty {
            return products.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } else {
            return products.filter { product in
                product.name.localizedCaseInsensitiveContains(query) ||
                (product.brand?.localizedCaseInsensitiveContains(query) ?? false) ||
                product.store.localizedCaseInsensitiveContains(query)
            }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }
}
