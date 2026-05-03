//
//  ShoppingAnalyticsManager.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 18/09/2025.
//

import Foundation
import Combine

struct StoreShoppingCost {
    let storeName: String
    let totalCost: Double
    let itemCount: Int
    let unavailableItems: [String] // Items not available at this store
}

struct OptimalShoppingBreakdown {
    let totalCost: Double
    let storeBreakdown: [StoreOptimalPurchase]
    let potentialSavings: Double // Compared to shopping at single most expensive store
}

struct StoreOptimalPurchase {
    let storeName: String
    let items: [OptimalPurchaseItem]
    let subtotal: Double
}

struct OptimalPurchaseItem {
    let productName: String
    let price: Double
}

struct NutriScoreBreakdown {
    let gradeA: Int
    let gradeB: Int
    let gradeC: Int
    let gradeD: Int
    let gradeE: Int
    let unknown: Int
    let totalItems: Int
    
    var healthScore: Double {
        let totalGraded = gradeA + gradeB + gradeC + gradeD + gradeE
        guard totalGraded > 0 else { return 0 }
        
        // Weight grades: A=5, B=4, C=3, D=2, E=1
        let weightedScore = (gradeA * 5) + (gradeB * 4) + (gradeC * 3) + (gradeD * 2) + (gradeE * 1)
        return Double(weightedScore) / Double(totalGraded * 5) * 100 // Convert to percentage
    }
    
    var healthMessage: String {
        let score = healthScore
        
        switch score {
        case 90...100:
            return "Outstanding! Almost everything you chose is super healthy 🌱"
        case 80..<90:
            return "Excellent! Your shopping list is very healthy 💚"
        case 70..<80:
            return "Great job! You're making strong healthy choices 👍"
        case 60..<70:
            return "Good effort! Most of your products are healthy"
        case 50..<60:
            return "Not bad, but you could pick a few more healthier options"
        case 40..<50:
            return "Your shopping list is leaning unhealthy, try adding more nutritious foods"
        case 30..<40:
            return "Quite a few items are unhealthy, consider healthier alternatives"
        case 20..<30:
            return "Your shopping is mostly unhealthy, time to rethink some choices"
        case 10..<20:
            return "Warning: Very unhealthy list. Try balancing with fruits, veggies, or whole foods"
        default: // 0..<10
            return "⚠️ Extremely unhealthy! Please consider a major change in your shopping habits"
        }
    }
    
    var healthMessageColor: String {
        let score = healthScore
        
        switch score {
        case 80...100:
            return "green" // Outstanding & Excellent
        case 70..<80:
            return "lightGreen" // Great job
        case 50..<70:
            return "yellow" // Good effort & Not bad
        case 30..<50:
            return "orange" // Leaning unhealthy & Quite a few unhealthy
        default: // 0..<30
            return "red" // Mostly unhealthy, Very unhealthy, Extremely unhealthy
        }
    }
}

class ShoppingAnalyticsManager: ObservableObject {
    static let shared = ShoppingAnalyticsManager()
    
    @Published var storeAnalytics: [StoreShoppingCost] = []
    @Published var optimalShopping: OptimalShoppingBreakdown?
    @Published var nutriScoreBreakdown: NutriScoreBreakdown?
    @Published var isCalculating = false
    
    let multiStoreManager = MultiStoreProductManager.shared
    let shoppingListManager = FirestoreShoppingListManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Listen for changes in shopping list or products
        Publishers.CombineLatest(
            multiStoreManager.$products,
            shoppingListManager.$shoppingListProductIds
        )
        .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
        .sink { [weak self] _, _ in
            self?.calculateAnalytics()
        }
        .store(in: &cancellables)
    }
    
    private func calculateAnalytics() {
        guard !shoppingListManager.shoppingListProductIds.isEmpty else {
            storeAnalytics = []
            optimalShopping = nil
            nutriScoreBreakdown = nil
            return
        }
        
        isCalculating = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let shoppingListProducts = self.getShoppingListProducts()
            let storeAnalytics = self.calculateStoreAnalytics(products: shoppingListProducts)
            let optimalShopping = self.calculateOptimalShopping(products: shoppingListProducts)
            let nutriScoreBreakdown = self.calculateNutriScoreBreakdown(products: shoppingListProducts)
            
            DispatchQueue.main.async {
                self.storeAnalytics = storeAnalytics
                self.optimalShopping = optimalShopping
                self.nutriScoreBreakdown = nutriScoreBreakdown
                self.isCalculating = false
            }
        }
    }
    
    private func getShoppingListProducts() -> [ProductWithMultipleStores] {
        return multiStoreManager.products.filter { product in
            shoppingListManager.isInShoppingList(productId: product.id)
        }
    }
    
    private func calculateStoreAnalytics(products: [ProductWithMultipleStores]) -> [StoreShoppingCost] {
        guard !products.isEmpty else { return [] }
        
        // Get all unique stores (sorted for consistent ordering)
        let allStores = Set(products.flatMap { $0.storePrices.map { $0.store } }).sorted()
        
        var storeAnalytics: [StoreShoppingCost] = []
        
        for store in allStores {
            var totalCost: Double = 0
            var itemCount: Int = 0
            var unavailableItems: [String] = []
            
            for product in products {
                if let storePrice = product.storePrices.first(where: { $0.store == store }) {
                    totalCost += storePrice.price
                    itemCount += 1
                } else {
                    unavailableItems.append(product.name)
                }
            }
            
            let storeCost = StoreShoppingCost(
                storeName: store,
                totalCost: totalCost,
                itemCount: itemCount,
                unavailableItems: unavailableItems
            )
            storeAnalytics.append(storeCost)
        }
        
        // Sort by total cost (ascending)
        return storeAnalytics.sorted { $0.totalCost < $1.totalCost }
    }
    
    private func calculateOptimalShopping(products: [ProductWithMultipleStores]) -> OptimalShoppingBreakdown {
        guard !products.isEmpty else {
            return OptimalShoppingBreakdown(totalCost: 0, storeBreakdown: [], potentialSavings: 0)
        }
        
        var storeBreakdown: [String: [OptimalPurchaseItem]] = [:]
        var totalOptimalCost: Double = 0
        
        // For each product, find the cheapest store
        for product in products {
            guard let cheapestStorePrice = product.storePrices.min(by: { $0.price < $1.price }) else {
                continue
            }
            
            let item = OptimalPurchaseItem(
                productName: product.name,
                price: cheapestStorePrice.price
            )
            
            if storeBreakdown[cheapestStorePrice.store] == nil {
                storeBreakdown[cheapestStorePrice.store] = []
            }
            storeBreakdown[cheapestStorePrice.store]?.append(item)
            totalOptimalCost += cheapestStorePrice.price
        }
        
        // Convert to StoreOptimalPurchase array
        let storeOptimalPurchases = storeBreakdown.map { storeName, items in
            StoreOptimalPurchase(
                storeName: storeName,
                items: items,
                subtotal: items.reduce(0) { $0 + $1.price }
            )
        }.sorted { $0.subtotal > $1.subtotal } // Sort by subtotal descending
        
        // Calculate potential savings (compared to most expensive single store)
        let mostExpensiveStoreCost = storeAnalytics.max(by: { $0.totalCost < $1.totalCost })?.totalCost ?? 0
        let potentialSavings = max(0, mostExpensiveStoreCost - totalOptimalCost)
        
        return OptimalShoppingBreakdown(
            totalCost: totalOptimalCost,
            storeBreakdown: storeOptimalPurchases,
            potentialSavings: potentialSavings
        )
    }
    
    private func calculateNutriScoreBreakdown(products: [ProductWithMultipleStores]) -> NutriScoreBreakdown {
        var gradeA = 0
        var gradeB = 0
        var gradeC = 0
        var gradeD = 0
        var gradeE = 0
        var unknown = 0
        
        for product in products {
            if let grade = product.nutriscoreGrade?.lowercased() {
                switch grade {
                case "a":
                    gradeA += 1
                case "b":
                    gradeB += 1
                case "c":
                    gradeC += 1
                case "d":
                    gradeD += 1
                case "e":
                    gradeE += 1
                default:
                    unknown += 1
                }
            } else {
                unknown += 1
            }
        }
        
        return NutriScoreBreakdown(
            gradeA: gradeA,
            gradeB: gradeB,
            gradeC: gradeC,
            gradeD: gradeD,
            gradeE: gradeE,
            unknown: unknown,
            totalItems: products.count
        )
    }
    
    // Helper methods for UI
    func getStoreCostPercentage(for store: StoreShoppingCost) -> Double {
        guard let maxCost = storeAnalytics.map(\.totalCost).max(), maxCost > 0 else { return 0 }
        return (store.totalCost / maxCost) * 100
    }
    
    func getStoreOptimalPercentage(for store: StoreOptimalPurchase) -> Double {
        guard let totalOptimal = optimalShopping?.totalCost, totalOptimal > 0 else { return 0 }
        return (store.subtotal / totalOptimal) * 100
    }
    
    func formatCurrency(_ amount: Double, currency: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}
