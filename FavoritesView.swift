//
//  FavoritesView.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 10/09/2025.
//

import SwiftUI

struct FavoritesView: View {
    @StateObject private var firestoreDatabase = FirestoreProductDatabase.shared
    @StateObject private var multiStoreManager = MultiStoreProductManager.shared
    @StateObject private var shoppingListManager = FirestoreShoppingListManager.shared
    @ObservedObject private var navigationCoordinator = NavigationCoordinator.shared
    @AppStorage("defaultCurrency") private var defaultCurrency: String = "EUR"
    @State private var showingDeleteAllAlert = false
    
    private func deleteAllItems() {
        // Remove all items from the shopping list using base product IDs
        for multiStoreProduct in multiStoreManager.products {
            if shoppingListManager.isInShoppingList(productId: multiStoreProduct.id) {
                shoppingListManager.removeFromShoppingList(productId: multiStoreProduct.id)
            }
        }
    }
    
    // Extract base product ID (remove store suffix if present)
    private func getBaseProductId(from productId: String) -> String {
        if productId.contains("_") {
            return String(productId.split(separator: "_").first ?? "")
        }
        return productId
    }
    
    
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Fixed Header - doesn't scroll
                VStack {
                    HStack {
                        Text("My List")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Delete all button
                        if !shoppingListManager.shoppingListProductIds.isEmpty {
                            Button(action: {
                                showingDeleteAllAlert = true
                            }) {
                                Text("Delete List")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.red)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                }
                .background(Color.appBackground)
                
                // Fixed Compact Shopping Optimizer Section
                CompactShoppingOptimizerView(initialStoreCount: navigationCoordinator.shoppingListStoreCount)
                    .background(Color.appBackground)
                    .padding(.horizontal, 4) // Add horizontal padding to the entire section
                    .padding(.bottom, 12) // Increased bottom padding
                    .onChange(of: navigationCoordinator.shoppingListStoreCount) { storeCount in
                        if storeCount != nil {
                            // Clear the navigation state after handling
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                navigationCoordinator.clearNavigation()
                            }
                        }
                    }
                
                // Scrollable Store Lists Content
                ScrollView {
                    ShoppingStoreListsView(shouldExpandAll: navigationCoordinator.shoppingListStoreCount != nil)
                        .background(Color.appBackground)
                }
            }
            .background(Color.appBackground)
            .navigationBarHidden(true)
            .alert("Delete All Items", isPresented: $showingDeleteAllAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete All", role: .destructive) {
                    deleteAllItems()
                }
            } message: {
                Text("Are you sure? All items will be deleted from the list.")
            }
        }
    }
}

// MARK: - Compact Shopping Optimizer View
struct CompactShoppingOptimizerView: View {
    @StateObject private var optimizer = ShoppingOptimizer.shared
    @AppStorage("defaultCurrency") private var defaultCurrency: String = "EUR"
    let initialStoreCount: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Compact header
            Text("SHOPPING OPTIMIZER")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.horizontal, 24)
                .padding(.top, 4)
            
            if optimizer.isCalculating {
                // Compact loading state
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Calculating...")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.appItemBackground)
                .cornerRadius(8)
                .padding(.horizontal, 20)
            } else if optimizer.optimizedPlans.isEmpty {
                // Compact empty state
                HStack(spacing: 12) {
                    Image(systemName: "cart.badge.questionmark")
                        .font(.system(size: 16))
                        .foregroundColor(.orange)
                    Text("Add products to see optimization options")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.appItemBackground)
                .cornerRadius(8)
                .padding(.horizontal, 20)
            } else {
                // Compact optimization options - horizontal scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(optimizer.optimizedPlans, id: \.maxStores) { plan in
                            CompactOptimizationCard(
                                plan: plan,
                                currency: defaultCurrency,
                                isSelected: optimizer.selectedMaxStores == plan.maxStores,
                                onSelect: {
                                    optimizer.selectPlan(maxStores: plan.maxStores)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24) // Increased from 20 to 24
                    .padding(.vertical, 8) // Added vertical padding
                }
            }
        }
        .onAppear {
            optimizer.calculateOptimizedPlans()
            
            // If navigating from dashboard with specific store count, select it
            if let storeCount = initialStoreCount {
                print("DEBUG: CompactShoppingOptimizerView - Selecting \(storeCount) store(s) from navigation")
                optimizer.selectPlan(maxStores: storeCount)
            } else {
                // Otherwise, ensure 1-store option is selected by default
                if !optimizer.optimizedPlans.isEmpty && optimizer.selectedMaxStores != 1 {
                    optimizer.selectPlan(maxStores: 1)
                }
            }
        }
    }
}

// MARK: - Compact Optimization Card
struct CompactOptimizationCard: View {
    let plan: OptimizedShoppingPlan
    let currency: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack {
                Spacer()
                
                // Exactly 3 lines of text, vertically centered as a group
                VStack(spacing: 4) {
                    // Line 1: Store name or store count
                    if plan.maxStores == 1 {
                        let storeName = plan.storeVisits.first?.storeName ?? "Store"
                        Text(storeName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("\(plan.maxStores) stores")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Line 2: Price with currency
                    Text("\(String(format: "%.2f", plan.totalCost)) \(currency)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // Line 3: Label (Easiest or savings)
                    if plan.maxStores == 1 {
                        Text("Easiest")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                    } else if plan.savings > 0 {
                        Text("save \(String(format: "%.2f", plan.savings)) \(currency)")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                    } else {
                        Text(" ")
                            .font(.system(size: 9))
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
            .frame(width: 90, height: 70) // Fixed size for all buttons
            .background(isSelected ? Color.blue.opacity(0.15) : Color.appItemBackground)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected ? Color.blue : Color(.systemGray5), 
                        lineWidth: isSelected ? 3 : 1
                    )
            )
            .shadow(
                color: isSelected ? Color.blue.opacity(0.2) : Color.clear,
                radius: isSelected ? 2 : 0,
                x: 0,
                y: 0
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Shopping Store Lists View
struct ShoppingStoreListsView: View {
    @StateObject private var optimizer = ShoppingOptimizer.shared
    @AppStorage("defaultCurrency") private var defaultCurrency: String = "EUR"
    @State private var expandedStores: Set<String> = []
    let shouldExpandAll: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            if let selectedPlan = optimizer.selectedPlan {
                LazyVStack(spacing: 0, pinnedViews: []) {
                    ForEach(Array(selectedPlan.storeVisits.enumerated()), id: \.element.storeName) { index, storeVisit in
                        StoreVisitCard(
                            storeVisit: storeVisit,
                            currency: defaultCurrency,
                            storeNumber: index + 1,
                            isExpanded: expandedStores.contains(storeVisit.storeName),
                            onToggleExpansion: {
                                if expandedStores.contains(storeVisit.storeName) {
                                    expandedStores.remove(storeVisit.storeName)
                                } else {
                                    expandedStores.insert(storeVisit.storeName)
                                }
                            },
                            onItemToggle: nil
                        )
                        .id("store_\(storeVisit.storeName)")
                        
                        if index < selectedPlan.storeVisits.count - 1 {
                            Divider()
                                .padding(.leading, 20)
                        }
                    }
                }
                .background(Color.appItemBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .onChange(of: shouldExpandAll) { expand in
            if expand {
                // Delay to ensure selectedPlan is updated first
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let selectedPlan = optimizer.selectedPlan {
                        expandedStores = Set(selectedPlan.storeVisits.map { $0.storeName })
                        print("DEBUG: ShoppingStoreListsView - Expanded all stores: \(expandedStores)")
                    }
                }
            }
        }
        .onChange(of: optimizer.selectedPlan) { plan in
            // Also expand when plan changes and shouldExpandAll is true
            if shouldExpandAll, let selectedPlan = plan {
                expandedStores = Set(selectedPlan.storeVisits.map { $0.storeName })
                print("DEBUG: ShoppingStoreListsView - Expanded all stores on plan change: \(expandedStores)")
            }
        }
        .onAppear {
            if shouldExpandAll {
                // Delay to ensure selectedPlan is available
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    if let selectedPlan = optimizer.selectedPlan {
                        expandedStores = Set(selectedPlan.storeVisits.map { $0.storeName })
                        print("DEBUG: ShoppingStoreListsView - Expanded all stores on appear: \(expandedStores)")
                    }
                }
            }
        }
    }
}

#Preview {
    FavoritesView()
}
