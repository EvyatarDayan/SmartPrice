//
//  MultiStoreProductManager.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 18/09/2025.
//

import Foundation
import Combine

class MultiStoreProductManager: ObservableObject {
    static let shared = MultiStoreProductManager()
    
    @Published var products: [ProductWithMultipleStores] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firestoreDatabase = FirestoreProductDatabase.shared
    private let storeManager = StoreManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Listen to changes in the legacy product database and enabled stores
        Publishers.CombineLatest(
            firestoreDatabase.$products,
            storeManager.$enabledStores
        )
        .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
        .sink { [weak self] legacyProducts, enabledStores in
            print("DEBUG: MultiStoreProductManager - Store filter changed! Enabled stores: \(enabledStores)")
            print("DEBUG: MultiStoreProductManager - Received \(legacyProducts.count) products from FirestoreProductDatabase")
            print("DEBUG: MultiStoreProductManager - Reprocessing products with new store filter...")
            self?.processLegacyProducts(legacyProducts)
        }
        .store(in: &cancellables)
    }
    
    private func processLegacyProducts(_ legacyProducts: [Product]) {
        print("DEBUG: MultiStoreProductManager - Processing \(legacyProducts.count) legacy products")
        
        // Log unique store names in products
        let uniqueStores = Set(legacyProducts.map { $0.store })
        print("DEBUG: MultiStoreProductManager - Unique stores in products: \(uniqueStores)")
        
        // Filter products by enabled stores
        let enabledProducts = legacyProducts.filter { product in
            let isEnabled = storeManager.isStoreEnabled(product.store)
            if !isEnabled {
                print("DEBUG: MultiStoreProductManager - Filtering out product '\(product.name)' from store '\(product.store)'")
            }
            return isEnabled
        }
        
        print("DEBUG: MultiStoreProductManager - \(enabledProducts.count) products from enabled stores (out of \(legacyProducts.count) total)")
        
        var productGroups: [String: ProductWithMultipleStores] = [:]
        
        for product in enabledProducts {
            // Generate product ID without store
            let baseId = generateBaseProductId(name: product.name, brand: product.brand, category: product.category, barcode: product.barcode)
            
            if var existingProduct = productGroups[baseId] {
                // Add this store's price to existing product
                existingProduct.addOrUpdateStorePrice(store: product.store, price: product.price, date: product.date)
                productGroups[baseId] = existingProduct
            } else {
                // Create new product with this store's price
                let newProduct = ProductWithMultipleStores(
                    id: baseId,
                    name: product.name,
                    brand: product.brand,
                    category: product.category,
                    barcode: product.barcode,
                    imageData: product.imageData,
                    imageUrl: product.imageUrl,
                    iconName: product.iconName,
                    isChecked: product.isChecked,
                    isInShoppingList: product.isInShoppingList,
                    nutriscoreGrade: product.nutriscoreGrade,
                    nutritionalInfo: product.nutritionalInfo,
                    ingredients: product.ingredients,
                    allergens: product.allergens,
                    traces: product.traces,
                    storePrices: [StorePrice(store: product.store, price: product.price, date: product.date)]
                )
                productGroups[baseId] = newProduct
            }
        }
        
        let finalProducts = Array(productGroups.values).sorted { $0.name < $1.name }
        
        DispatchQueue.main.async {
            self.products = finalProducts
            print("DEBUG: MultiStoreProductManager - Final products count: \(self.products.count)")
            print("DEBUG: MultiStoreProductManager - Products updated on main thread")
        }
    }
    
    private func generateBaseProductId(name: String, brand: String?, category: String, barcode: String?) -> String {
        let contentString = "\(name.lowercased())|\(brand?.lowercased() ?? "")|\(category.lowercased())|\(barcode ?? "")"
        return SHA256.hash(data: contentString.data(using: .utf8)!).compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // Get product by base ID
    func getProduct(by baseId: String) -> ProductWithMultipleStores? {
        return products.first { $0.id == baseId }
    }
    
    // Add or update a product with store price
    func addOrUpdateProduct(name: String, brand: String?, category: String, barcode: String?, store: String, price: Double, imageData: Data? = nil, imageUrl: String? = nil, iconName: String? = nil, nutriscoreGrade: String? = nil, nutritionalInfo: NutritionalInfo? = nil, ingredients: String? = nil, allergens: String? = nil, traces: String? = nil) {
        
        // Create legacy product for the database
        let legacyProduct = Product(
            name: name,
            brand: brand,
            category: category,
            barcode: barcode,
            store: store,
            price: price,
            date: Date(),
            imageData: imageData,
            imageUrl: imageUrl,
            iconName: iconName,
            nutriscoreGrade: nutriscoreGrade,
            nutritionalInfo: nutritionalInfo,
            ingredients: ingredients,
            allergens: allergens,
            traces: traces
        )
        
        // Add to legacy database (this will trigger the update process)
        firestoreDatabase.addProduct(legacyProduct, imageData: imageData)
    }
    
    // Get the best price for a product
    func getBestPrice(for productId: String) -> (store: String, price: Double)? {
        guard let product = getProduct(by: productId),
              let bestStorePrice = product.storePrices.min(by: { $0.price < $1.price }) else {
            return nil
        }
        return (store: bestStorePrice.store, price: bestStorePrice.price)
    }
    
    // Get all store prices for a product
    func getStorePrices(for productId: String) -> [StorePrice] {
        return getProduct(by: productId)?.sortedStorePrices ?? []
    }
    
    // Update a specific store price for a product
    func updateStorePrice(productId: String, store: String, newPrice: Double) {
        // Find the legacy product and update it
        if let legacyProduct = firestoreDatabase.products.first(where: { 
            generateBaseProductId(name: $0.name, brand: $0.brand, category: $0.category, barcode: $0.barcode) == productId && $0.store == store 
        }) {
            let updatedProduct = Product(
                id: legacyProduct.id,
                name: legacyProduct.name,
                brand: legacyProduct.brand,
                category: legacyProduct.category,
                barcode: legacyProduct.barcode,
                store: store,
                price: newPrice,
                date: Date(),
                imageData: legacyProduct.imageData,
                imageUrl: legacyProduct.imageUrl,
                iconName: legacyProduct.iconName,
                isChecked: legacyProduct.isChecked,
                isInShoppingList: legacyProduct.isInShoppingList,
                nutriscoreGrade: legacyProduct.nutriscoreGrade,
                nutritionalInfo: legacyProduct.nutritionalInfo
            )
            firestoreDatabase.updateProduct(updatedProduct)
        }
    }
    
    // Refresh products from database
    func refreshProducts() {
        print("DEBUG: 🔄 MultiStoreProductManager - Refreshing products from database")
        firestoreDatabase.refreshProducts()
    }
    
    // Remove a store price for a product
    func removeStorePrice(productId: String, store: String) {
        // Find and delete the legacy product for this store
        if let legacyProduct = firestoreDatabase.products.first(where: { 
            generateBaseProductId(name: $0.name, brand: $0.brand, category: $0.category, barcode: $0.barcode) == productId && $0.store == store 
        }) {
            firestoreDatabase.deleteProduct(legacyProduct)
        }
    }
}

import CryptoKit // For SHA256 hashing

