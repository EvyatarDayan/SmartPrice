//
//  PriceMonitoringService.swift
//  SmartPrice
//
//  Created by AI Assistant on 06/10/2025.
//

import Foundation
import Combine

class PriceMonitoringService: ObservableObject {
    static let shared = PriceMonitoringService()
    
    private let multiStoreManager = MultiStoreProductManager.shared
    private let shoppingListManager = FirestoreShoppingListManager.shared
    private let notificationManager = NotificationManager.shared
    private let currencyManager = CurrencyManager.shared
    
    private var cancellables = Set<AnyCancellable>()
    private var previousPrices: [String: [String: Double]] = [:] // [productId: [store: price]]
    
    private init() {
        setupPriceMonitoring()
        loadPreviousPrices()
    }
    
    // MARK: - Price Monitoring Setup
    
    private func setupPriceMonitoring() {
        // Monitor changes to products and shopping list
        Publishers.CombineLatest(
            multiStoreManager.$products,
            shoppingListManager.$shoppingListProductIds
        )
        .debounce(for: .milliseconds(1000), scheduler: RunLoop.main)
        .sink { [weak self] products, shoppingListIds in
            self?.checkForPriceChanges(products: products, shoppingListIds: shoppingListIds)
        }
        .store(in: &cancellables)
    }
    
    // MARK: - Price Change Detection
    
    private func checkForPriceChanges(products: [ProductWithMultipleStores], shoppingListIds: [String: Bool]) {
        print("DEBUG: 🔍 checkForPriceChanges called with \(products.count) products")
        print("DEBUG: 🔍 Shopping list has \(shoppingListIds.count) items")
        print("DEBUG: 🔍 Notification enabled: \(notificationManager.isNotificationEnabled)")
        
        guard notificationManager.isNotificationEnabled else {
            print("DEBUG: ❌ Price monitoring disabled - notifications not enabled")
            return
        }
        
        // Only monitor products in shopping list
        let shoppingListProducts = products.filter { product in
            shoppingListIds.keys.contains(product.id)
        }
        
        print("DEBUG: 📊 Monitoring \(shoppingListProducts.count) products for price changes")
        print("DEBUG: 📊 Shopping list product IDs: \(Array(shoppingListIds.keys))")
        print("DEBUG: 📊 Available product IDs: \(products.map { $0.id })")
        
        if shoppingListProducts.isEmpty {
            print("DEBUG: ⚠️ No products to monitor - either empty shopping list or no matching products")
        }
        
        for product in shoppingListProducts {
            print("DEBUG: 🔍 Checking product: \(product.name) (ID: \(product.id))")
            checkProductPriceChanges(product: product)
        }
        
        // Save current prices for next comparison
        savePrices(products: shoppingListProducts)
    }
    
    private func checkProductPriceChanges(product: ProductWithMultipleStores) {
        print("DEBUG: 💰 Checking prices for product: \(product.name)")
        print("DEBUG: 💰 Current store prices: \(product.storePrices.map { "\($0.store): \($0.price)" })")
        
        guard let previousProductPrices = previousPrices[product.id] else {
            print("DEBUG: 💰 First time seeing product \(product.name) - saving initial prices")
            return
        }
        
        print("DEBUG: 💰 Previous prices: \(previousProductPrices)")
        
        for storePrice in product.storePrices {
            let store = storePrice.store
            let currentPrice = storePrice.price
            
            print("DEBUG: 💰 Checking \(store): current=\(currentPrice)")
            
            if let previousPrice = previousProductPrices[store] {
                print("DEBUG: 💰 Previous price for \(store): \(previousPrice)")
                
                // Check if price changed significantly (more than 0.01 to avoid floating point issues)
                let priceChange = abs(currentPrice - previousPrice)
                
                print("DEBUG: 💰 Price difference: \(priceChange)")
                
                if priceChange > 0.01 {
                    print("DEBUG: 🚨 PRICE CHANGE DETECTED for \(product.name) at \(store): \(previousPrice) -> \(currentPrice)")
                    
                    // Send notification
                    notificationManager.sendPriceChangeNotification(
                        productName: product.name,
                        oldPrice: previousPrice,
                        newPrice: currentPrice,
                        currency: currencyManager.defaultCurrency,
                        store: store,
                        productId: product.id
                    )
                    
                    // Log price change
                    logPriceChange(
                        productName: product.name,
                        store: store,
                        oldPrice: previousPrice,
                        newPrice: currentPrice
                    )
                } else {
                    print("DEBUG: 💰 No significant price change for \(product.name) at \(store)")
                }
            } else {
                print("DEBUG: 💰 No previous price found for \(product.name) at \(store) - new store")
            }
        }
    }
    
    // MARK: - Price Storage
    
    private func savePrices(products: [ProductWithMultipleStores]) {
        var newPrices: [String: [String: Double]] = [:]
        
        for product in products {
            var productPrices: [String: Double] = [:]
            for storePrice in product.storePrices {
                productPrices[storePrice.store] = storePrice.price
            }
            newPrices[product.id] = productPrices
        }
        
        previousPrices = newPrices
        savePreviousPrices()
    }
    
    private func loadPreviousPrices() {
        if let data = UserDefaults.standard.data(forKey: "previousPrices"),
           let decoded = try? JSONDecoder().decode([String: [String: Double]].self, from: data) {
            previousPrices = decoded
            print("DEBUG: Loaded \(previousPrices.count) previous price records")
        }
    }
    
    private func savePreviousPrices() {
        if let encoded = try? JSONEncoder().encode(previousPrices) {
            UserDefaults.standard.set(encoded, forKey: "previousPrices")
            print("DEBUG: Saved \(previousPrices.count) price records")
        }
    }
    
    // MARK: - Price Change Logging
    
    private func logPriceChange(productName: String, store: String, oldPrice: Double, newPrice: Double) {
        let priceChange = newPrice - oldPrice
        let changeDirection = priceChange > 0 ? "↗️" : "↘️"
        let changeAmount = abs(priceChange)
        let currency = currencyManager.defaultCurrency
        
        print("DEBUG: 💰 PRICE CHANGE \(changeDirection)")
        print("DEBUG: Product: \(productName)")
        print("DEBUG: Store: \(store)")
        print("DEBUG: Old Price: \(String(format: "%.2f", oldPrice)) \(currency)")
        print("DEBUG: New Price: \(String(format: "%.2f", newPrice)) \(currency)")
        print("DEBUG: Change: \(priceChange > 0 ? "+" : "")\(String(format: "%.2f", priceChange)) \(currency)")
    }
    
    // MARK: - Manual Price Check
    
    func forceCheckPrices() {
        print("DEBUG: 🔄 Forcing price check...")
        checkForPriceChanges(
            products: multiStoreManager.products,
            shoppingListIds: shoppingListManager.shoppingListProductIds
        )
    }
    
    func refreshDataAndCheckPrices() {
        print("DEBUG: 🔄 Refreshing data and checking prices...")
        
        // Force refresh of product data
        multiStoreManager.refreshProducts()
        
        // Wait a moment for data to refresh, then check prices
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.forceCheckPrices()
        }
    }
    
    // MARK: - Testing
    
    func simulatePriceChange() {
        guard let firstProduct = multiStoreManager.products.first,
              let firstStore = firstProduct.storePrices.first else {
            print("DEBUG: No products available for price simulation")
            return
        }
        
        let simulatedOldPrice = firstStore.price
        let simulatedNewPrice = simulatedOldPrice * 0.9 // 10% discount
        
        print("DEBUG: Simulating price change for testing")
        notificationManager.sendPriceChangeNotification(
            productName: firstProduct.name,
            oldPrice: simulatedOldPrice,
            newPrice: simulatedNewPrice,
            currency: currencyManager.defaultCurrency,
            store: firstStore.store
        )
    }
    
    // MARK: - Statistics
    
    var monitoredProductsCount: Int {
        let shoppingListIds = shoppingListManager.shoppingListProductIds
        return multiStoreManager.products.filter { product in
            shoppingListIds.keys.contains(product.id)
        }.count
    }
    
    var totalPriceRecordsCount: Int {
        return previousPrices.values.reduce(0) { total, storePrices in
            total + storePrices.count
        }
    }
}
