//
//  ShoppingOptimizer.swift
//  SmartPrice
//
//  Created by AI Assistant on 01/10/2025.
//

import Foundation
import Combine

struct OptimizedShoppingPlan: Equatable {
    let maxStores: Int
    let totalCost: Double
    let storeVisits: [StoreVisit]
    let savings: Double // Compared to single most expensive store
    let convenience: Double // Score from 0-100 (100 = single store, lower = more stores)
    
    static func == (lhs: OptimizedShoppingPlan, rhs: OptimizedShoppingPlan) -> Bool {
        return lhs.maxStores == rhs.maxStores &&
               lhs.totalCost == rhs.totalCost &&
               lhs.storeVisits.count == rhs.storeVisits.count
    }
}

struct StoreVisit {
    let storeName: String
    let items: [ShoppingItem]
    let subtotal: Double
}

struct ShoppingItem {
    let productId: String
    let productName: String
    let price: Double
}

class ShoppingOptimizer: ObservableObject {
    static let shared = ShoppingOptimizer()
    
    @Published var optimizedPlans: [OptimizedShoppingPlan] = []
    @Published var selectedMaxStores: Int = 1
    @Published var isCalculating = false
    
    private let multiStoreManager = MultiStoreProductManager.shared
    private let shoppingListManager = FirestoreShoppingListManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    /// Returns the actual count of items in the shopping list (only products that exist in the database)
    var shoppingListItemCount: Int {
        return getShoppingListProducts().count
    }
    
    private init() {
        // Listen for changes in shopping list or products
        Publishers.CombineLatest(
            multiStoreManager.$products,
            shoppingListManager.$shoppingListProductIds
        )
        .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
        .sink { [weak self] _, _ in
            self?.calculateOptimizedPlans()
        }
        .store(in: &cancellables)
    }
    
    func calculateOptimizedPlans() {
        guard !shoppingListManager.shoppingListProductIds.isEmpty else {
            optimizedPlans = []
            return
        }
        
        isCalculating = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let shoppingListProducts = self.getShoppingListProducts()
            let plans = self.generateOptimizedPlans(products: shoppingListProducts)
            
            DispatchQueue.main.async {
                self.optimizedPlans = plans
                self.isCalculating = false
            }
        }
    }
    
    private func getShoppingListProducts() -> [ProductWithMultipleStores] {
        return multiStoreManager.products.filter { product in
            shoppingListManager.isInShoppingList(productId: product.id)
        }
    }
    
    private func generateOptimizedPlans(products: [ProductWithMultipleStores]) -> [OptimizedShoppingPlan] {
        guard !products.isEmpty else { return [] }
        
        // Get all available stores (sorted for consistent ordering)
        let allStores = Array(Set(products.flatMap { $0.storePrices.map { $0.store } })).sorted()
        let maxPossibleStores = min(allStores.count, products.count)
        
        print("DEBUG: ShoppingOptimizer - Available stores: \(allStores)")
        print("DEBUG: ShoppingOptimizer - Products count: \(products.count)")
        
        var plans: [OptimizedShoppingPlan] = []
        var bestSingleStoreCost = Double.infinity
        
        // Find the best single store option (one store that has all products)
        if let bestSingleStore = findBestSingleStore(products: products, allStores: allStores) {
            plans.append(bestSingleStore)
            bestSingleStoreCost = bestSingleStore.totalCost
        }
        
        // Generate plans for multi-store combinations (2, 3, etc. stores)
        var lastBestCost = bestSingleStoreCost
        if maxPossibleStores >= 2 {
            for storeCount in 2...maxPossibleStores {
            if let basePlan = findBestMultiStoreCombo(products: products, maxStores: storeCount, allStores: allStores) {
                // Calculate correct savings compared to best single store
                let savingsAmount = bestSingleStoreCost - basePlan.totalCost
                let savingsPercentage = bestSingleStoreCost > 0 && bestSingleStoreCost != Double.infinity ? 
                    (savingsAmount / bestSingleStoreCost) * 100 : 0
                
                // Create plan with correct savings
                let correctedPlan = OptimizedShoppingPlan(
                    maxStores: basePlan.maxStores,
                    totalCost: basePlan.totalCost,
                    storeVisits: basePlan.storeVisits,
                    savings: max(0, savingsAmount),
                    convenience: basePlan.convenience
                )
                
                print("DEBUG: \(storeCount) stores - Cost: $\(String(format: "%.2f", correctedPlan.totalCost)), Savings: $\(String(format: "%.2f", correctedPlan.savings)) (\(String(format: "%.1f", savingsPercentage))%)")
                
                // Only include multi-store plans if they actually use multiple stores and provide value
                let actualStoresUsed = correctedPlan.storeVisits.count
                let isActuallyMultiStore = actualStoresUsed > 1
                let hasSignificantSavings = savingsAmount >= 0.50 || savingsPercentage >= 2.0
                let isDifferentFromLastPlan = abs(lastBestCost - correctedPlan.totalCost) > 0.01 // Different cost by more than 1 cent
                
                // For 2-store option: include if it actually uses 2 stores and provides different cost
                // For 3+ stores: require meaningful savings AND different cost from previous plan
                if (storeCount == 2 && isActuallyMultiStore && isDifferentFromLastPlan) || 
                   (storeCount > 2 && hasSignificantSavings && isActuallyMultiStore && isDifferentFromLastPlan) {
                    plans.append(correctedPlan)
                    lastBestCost = correctedPlan.totalCost
                    print("DEBUG: Added \(storeCount)-store plan using \(actualStoresUsed) actual stores, cost: \(correctedPlan.totalCost)")
                } else {
                    if !isActuallyMultiStore {
                        print("DEBUG: Skipping \(storeCount)-store option - only uses \(actualStoresUsed) store(s)")
                    } else if !isDifferentFromLastPlan {
                        print("DEBUG: Skipping \(storeCount)-store option - same cost as previous plan (\(correctedPlan.totalCost))")
                    } else {
                        print("DEBUG: Stopping at \(storeCount) stores - insufficient savings")
                    }
                    break
                }
            }
            }
        }
        
        return plans.sorted { $0.maxStores < $1.maxStores }
    }
    
    
    private func findOptimalPlan(products: [ProductWithMultipleStores], maxStores: Int, allStores: [String]) -> OptimizedShoppingPlan? {
        if maxStores == 1 {
            return findBestSingleStore(products: products, allStores: allStores)
        } else {
            return findBestMultiStoreCombo(products: products, maxStores: maxStores, allStores: allStores)
        }
    }
    
    private func findBestSingleStore(products: [ProductWithMultipleStores], allStores: [String]) -> OptimizedShoppingPlan? {
        var bestPlan: OptimizedShoppingPlan?
        var bestCost = Double.infinity
        
        for store in allStores {
            var totalCost: Double = 0
            var items: [ShoppingItem] = []
            var canBuyAll = true
            
            for product in products {
                if let storePrice = product.storePrices.first(where: { $0.store == store }) {
                    totalCost += storePrice.price
                    items.append(ShoppingItem(
                        productId: product.id,
                        productName: product.name,
                        price: storePrice.price
                    ))
                } else {
                    canBuyAll = false
                    break
                }
            }
            
            if canBuyAll && totalCost < bestCost {
                bestCost = totalCost
                let storeVisit = StoreVisit(storeName: store, items: items, subtotal: totalCost)
                
                // Calculate savings compared to most expensive single store option
                let mostExpensiveCost = calculateMostExpensiveSingleStoreCost(products: products, allStores: allStores)
                let savings = max(0, mostExpensiveCost - totalCost)
                
                print("DEBUG: ShoppingOptimizer - New best single store: \(store) with cost \(totalCost)")
                
                bestPlan = OptimizedShoppingPlan(
                    maxStores: 1,
                    totalCost: totalCost,
                    storeVisits: [storeVisit],
                    savings: savings,
                    convenience: 100.0 // Single store = maximum convenience
                )
            }
        }
        
        return bestPlan
    }
    
    private func findBestMultiStoreCombo(products: [ProductWithMultipleStores], maxStores: Int, allStores: [String]) -> OptimizedShoppingPlan? {
        if maxStores == 2 {
            return findBestTwoStoreCombo(products: products, allStores: allStores)
        } else {
            return findBestMultiStoreComboGreedy(products: products, maxStores: maxStores, allStores: allStores)
        }
    }
    
    private func findBestTwoStoreCombo(products: [ProductWithMultipleStores], allStores: [String]) -> OptimizedShoppingPlan? {
        var bestPlan: OptimizedShoppingPlan?
        var bestTotalCost = Double.infinity
        
        // Try all combinations of 2 stores
        for i in 0..<allStores.count {
            for j in (i+1)..<allStores.count {
                let store1 = allStores[i]
                let store2 = allStores[j]
                
                var store1Items: [ShoppingItem] = []
                var store2Items: [ShoppingItem] = []
                var totalCost: Double = 0
                var canBuyAll = true
                
                // For each product, choose the cheaper store between the two (or the only available store)
                for product in products {
                    let store1Price = product.storePrices.first(where: { $0.store == store1 })?.price
                    let store2Price = product.storePrices.first(where: { $0.store == store2 })?.price
                    
                    if let price1 = store1Price, let price2 = store2Price {
                        // Both stores have the product, choose cheaper
                        if price1 <= price2 {
                            store1Items.append(ShoppingItem(productId: product.id, productName: product.name, price: price1))
                            totalCost += price1
                        } else {
                            store2Items.append(ShoppingItem(productId: product.id, productName: product.name, price: price2))
                            totalCost += price2
                        }
                    } else if let price1 = store1Price {
                        // Only store1 has the product
                        store1Items.append(ShoppingItem(productId: product.id, productName: product.name, price: price1))
                        totalCost += price1
                    } else if let price2 = store2Price {
                        // Only store2 has the product
                        store2Items.append(ShoppingItem(productId: product.id, productName: product.name, price: price2))
                        totalCost += price2
                    } else {
                        // Neither store has the product - this combination won't work
                        canBuyAll = false
                        break
                    }
                }
                
                // Only consider this combination if we can buy all products and it's cheaper
                if canBuyAll && totalCost < bestTotalCost {
                    bestTotalCost = totalCost
                    
                    var storeVisits: [StoreVisit] = []
                    if !store1Items.isEmpty {
                        storeVisits.append(StoreVisit(
                            storeName: store1,
                            items: store1Items,
                            subtotal: store1Items.reduce(0) { $0 + $1.price }
                        ))
                    }
                    if !store2Items.isEmpty {
                        storeVisits.append(StoreVisit(
                            storeName: store2,
                            items: store2Items,
                            subtotal: store2Items.reduce(0) { $0 + $1.price }
                        ))
                    }
                    
                    let mostExpensiveCost = calculateMostExpensiveSingleStoreCost(products: products, allStores: allStores)
                    let savings = max(0, mostExpensiveCost - totalCost)
                    
                    bestPlan = OptimizedShoppingPlan(
                        maxStores: 2,
                        totalCost: totalCost,
                        storeVisits: storeVisits.sorted { $0.subtotal > $1.subtotal },
                        savings: savings,
                        convenience: 80.0 // 2 stores = 80% convenience
                    )
                }
            }
        }
        
        return bestPlan
    }
    
    private func findBestMultiStoreComboGreedy(products: [ProductWithMultipleStores], maxStores: Int, allStores: [String]) -> OptimizedShoppingPlan? {
        // For 3+ stores, use the optimal assignment (each product to its cheapest store)
        var storeGroups: [String: [ShoppingItem]] = [:]
        var initialTotalCost: Double = 0
        
        for product in products {
            if let cheapestPrice = product.storePrices.min(by: { $0.price < $1.price }) {
                let item = ShoppingItem(
                    productId: product.id,
                    productName: product.name,
                    price: cheapestPrice.price
                )
                
                if storeGroups[cheapestPrice.store] == nil {
                    storeGroups[cheapestPrice.store] = []
                }
                storeGroups[cheapestPrice.store]?.append(item)
                initialTotalCost += cheapestPrice.price
            }
        }
        
        // If we have more stores than maxStores, we need to consolidate
        if storeGroups.count > maxStores {
            // Keep the stores with highest subtotals
            let sortedStores = storeGroups.map { storeName, items in
                (storeName: storeName, items: items, subtotal: items.reduce(0) { $0 + $1.price })
            }.sorted { $0.subtotal > $1.subtotal }
            
            let keepStores = Array(sortedStores.prefix(maxStores))
            let dropStores = Array(sortedStores.dropFirst(maxStores))
            let keepStoreNames = Set(keepStores.map { $0.storeName })
            
            // Reassign products from dropped stores to kept stores
            var finalStoreGroups: [String: [ShoppingItem]] = [:]
            var finalTotalCost: Double = 0
            
            // First, add all items from kept stores
            for keepStore in keepStores {
                finalStoreGroups[keepStore.storeName] = keepStore.items
                finalTotalCost += keepStore.subtotal
            }
            
            // Then reassign items from dropped stores
            for dropStore in dropStores {
                for item in dropStore.items {
                    // Find the original product to get all store prices
                    if let product = products.first(where: { $0.id == item.productId }) {
                        // Find the cheapest price among the kept stores
                        let availablePrices = product.storePrices.filter { keepStoreNames.contains($0.store) }
                        if let cheapestInKeptStores = availablePrices.min(by: { $0.price < $1.price }) {
                            let reassignedItem = ShoppingItem(
                                productId: product.id,
                                productName: product.name,
                                price: cheapestInKeptStores.price
                            )
                            
                            if finalStoreGroups[cheapestInKeptStores.store] == nil {
                                finalStoreGroups[cheapestInKeptStores.store] = []
                            }
                            finalStoreGroups[cheapestInKeptStores.store]?.append(reassignedItem)
                            
                            // Adjust total cost (remove old price, add new price)
                            finalTotalCost = finalTotalCost - item.price + cheapestInKeptStores.price
                        }
                    }
                }
            }
            
            storeGroups = finalStoreGroups
            initialTotalCost = finalTotalCost
        }
        
        let storeVisits = storeGroups.map { storeName, items in
            StoreVisit(
                storeName: storeName,
                items: items,
                subtotal: items.reduce(0) { $0 + $1.price }
            )
        }.sorted { $0.subtotal > $1.subtotal }
        
        guard !storeVisits.isEmpty else { return nil }
        
        let mostExpensiveCost = calculateMostExpensiveSingleStoreCost(products: products, allStores: allStores)
        let savings = max(0, mostExpensiveCost - initialTotalCost)
        let convenience = max(0, 100.0 - Double(storeVisits.count - 1) * 20.0)
        
        print("DEBUG: Greedy algorithm - Final store count: \(storeVisits.count), Total products: \(storeVisits.flatMap { $0.items }.count)")
        
        return OptimizedShoppingPlan(
            maxStores: maxStores,
            totalCost: initialTotalCost,
            storeVisits: storeVisits,
            savings: savings,
            convenience: convenience
        )
    }
    
    private func calculateMostExpensiveSingleStoreCost(products: [ProductWithMultipleStores], allStores: [String]) -> Double {
        var maxCost: Double = 0
        
        for store in allStores {
            var storeCost: Double = 0
            var canBuyAll = true
            
            for product in products {
                if let storePrice = product.storePrices.first(where: { $0.store == store }) {
                    storeCost += storePrice.price
                } else {
                    canBuyAll = false
                    break
                }
            }
            
            if canBuyAll {
                maxCost = max(maxCost, storeCost)
            }
        }
        
        return maxCost
    }
    
    func selectPlan(maxStores: Int) {
        selectedMaxStores = maxStores
    }
    
    var selectedPlan: OptimizedShoppingPlan? {
        return optimizedPlans.first { $0.maxStores == selectedMaxStores }
    }
}
