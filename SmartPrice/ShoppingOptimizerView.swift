//
//  ShoppingOptimizerView.swift
//  SmartPrice
//
//  Created by AI Assistant on 01/10/2025.
//

import SwiftUI

struct ShoppingOptimizerView: View {
    @StateObject private var optimizer = ShoppingOptimizer.shared
    @AppStorage("defaultCurrency") private var defaultCurrency: String = "EUR"
    @State private var expandedStores: Set<String> = [] // Track which stores are expanded
    
    private func getCurrencySymbol(for currency: String) -> String {
        switch currency {
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        case "SEK": return "kr"
        case "AUD": return "A$"
        case "CAD": return "C$"
        case "CHF": return "CHF"
        default: return "$"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("SHOPPING OPTIMIZER")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            
            if optimizer.isCalculating {
                // Loading state
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    Text("Calculating optimal shopping plans...")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color.appItemBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
                .padding(.horizontal, 20)
            } else if optimizer.optimizedPlans.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "cart.badge.questionmark")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    
                    Text("No Shopping List")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Add products to your shopping list to see optimization options.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color.appItemBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                    )
                .padding(.horizontal, 20)
            } else {
                // Optimization options
                VStack(spacing: 12) {
                    ForEach(optimizer.optimizedPlans, id: \.maxStores) { plan in
                        OptimizationOptionCard(
                            plan: plan,
                            currency: defaultCurrency,
                            isSelected: optimizer.selectedMaxStores == plan.maxStores,
                            onSelect: {
                                optimizer.selectPlan(maxStores: plan.maxStores)
                            }
                        )
                      }
                  }
                  .padding(.horizontal, 20)
                  
                  // Divider between filter buttons and store lists
                  Rectangle()
                      .fill(Color.gray.opacity(0.5))
                      .frame(height: 8)
                      .padding(.horizontal, 20)
                      .padding(.top, 38)
                      .padding(.bottom, 16)
                  
                          // Selected plan details - directly show stores
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
                                      .id("store_\(storeVisit.storeName)") // Stable ID for each store
                                      
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
                              .padding(.top, 20)
                          }
            }
        }
        .onAppear {
            optimizer.calculateOptimizedPlans()
            // Ensure 1-store option is selected by default
            if !optimizer.optimizedPlans.isEmpty && optimizer.selectedMaxStores != 1 {
                optimizer.selectPlan(maxStores: 1)
            }
        }
    }
}

struct OptimizationOptionCard: View {
    let plan: OptimizedShoppingPlan
    let currency: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    private func getCurrencySymbol(for currency: String) -> String {
        switch currency {
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        case "SEK": return "kr"
        case "AUD": return "A$"
        case "CAD": return "C$"
        case "CHF": return "CHF"
        default: return "$"
        }
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Store count indicator - fixed on left
                VStack(spacing: 4) {
                    Text("\(plan.maxStores)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(plan.maxStores == 1 ? "Store" : "Stores")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(width: 60, height: 60)
                .background(Color.blue)
                .clipShape(Circle())
                
                // Plan details
                VStack(alignment: .leading, spacing: 4) {
                    if plan.maxStores == 1 {
                        // Single store text: "Buy all in 'Willys' for 12.40 SEK"
                        let storeName = plan.storeVisits.first?.storeName ?? "Store"
                        Text("All at \"\(storeName)\" for \(String(format: "%.2f", plan.totalCost)) \(currency)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    } else if plan.maxStores == 2 {
                        // Two store text: "Buy all in 'Willys' and 'Hemköp' for 11.90"
                        let storeNames = plan.storeVisits.map { $0.storeName }
                        let storeText = storeNames.count >= 2 ? "\"\(storeNames[0])\" and \"\(storeNames[1])\"" : storeNames.map { "\"\($0)\"" }.joined(separator: " and ")
                        
                        Text("Shop at \(storeText) for \(String(format: "%.2f", plan.totalCost))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    } else {
                        // Multiple stores text: "Buy all in X stores for Y.YY"
                        Text("Shop at \(plan.maxStores) stores for \(String(format: "%.2f", plan.totalCost))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Right side - savings text only
                VStack(alignment: .trailing, spacing: 4) {
                    // Savings text on the right (only for multi-store options)
                    if plan.maxStores > 1 && plan.savings > 0 {
                        Text("save \(String(format: "%.2f", plan.savings)) \(currency)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
                  }
                  .padding(16)
                  .frame(maxWidth: .infinity) // Fixed width to prevent layout shifts
                  .background(isSelected ? Color.blue.opacity(0.1) : Color.appItemBackground)
                  .cornerRadius(12)
                  .overlay(
                      RoundedRectangle(cornerRadius: 12)
                          .stroke(isSelected ? Color.blue : Color(.systemGray5), lineWidth: isSelected ? 2 : 1)
                  )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StoreVisitCard: View {
    let storeVisit: StoreVisit
    let currency: String
    let storeNumber: Int
    let isExpanded: Bool
    let onToggleExpansion: () -> Void
    let onItemToggle: ((String) -> Void)?
    @ObservedObject private var multiStoreManager = MultiStoreProductManager.shared
    @ObservedObject private var shoppingListManager = FirestoreShoppingListManager.shared
    
    // Check if all items in this store are checked
    var allItemsChecked: Bool {
        guard !storeVisit.items.isEmpty else { return false }
        return storeVisit.items.allSatisfy { item in
            shoppingListManager.isChecked(productId: item.productId)
        }
    }
    
    // Toggle all items in this store
    private func toggleAllItems() {
        let shouldCheckAll = !allItemsChecked
        
        for item in storeVisit.items {
            let isCurrentlyChecked = shoppingListManager.isChecked(productId: item.productId)
            
            if shouldCheckAll && !isCurrentlyChecked {
                shoppingListManager.toggleChecked(productId: item.productId)
            } else if !shouldCheckAll && isCurrentlyChecked {
                shoppingListManager.toggleChecked(productId: item.productId)
            }
        }
    }
    
    private func getCurrencySymbol(for currency: String) -> String {
        switch currency {
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        case "SEK": return "kr"
        case "AUD": return "A$"
        case "CAD": return "C$"
        case "CHF": return "CHF"
        default: return "$"
        }
    }
    
    private func getProduct(for item: ShoppingItem) -> ProductWithMultipleStores? {
        return multiStoreManager.products.first { $0.id == item.productId }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Store header - clickable to expand/collapse
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    onToggleExpansion()
                }
            }) {
                HStack {
                    HStack(spacing: 12) {
                        // Store logo - smaller for compact view
                        if let store = Store.knownStores.first(where: { $0.name == storeVisit.storeName }) {
                            Image(store.logoName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                                .frame(width: 44, height: 44)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            Image(systemName: "storefront")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.blue)
                                .frame(width: 44, height: 44)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(storeVisit.storeName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text("(\(storeVisit.items.count) item\(storeVisit.items.count == 1 ? "" : "s"))")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Text("\(getCurrencySymbol(for: currency))\(String(format: "%.2f", storeVisit.subtotal))")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.green)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())
            .background(Color.blue.opacity(0.15))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue, lineWidth: 3)
            )
            .shadow(
                color: Color.blue.opacity(0.2),
                radius: 2,
                x: 0,
                y: 0
            )
            .padding(.horizontal, 4)
            .padding(.top, 4)
            .padding(.bottom, 8)
            
            // Expandable content
            if isExpanded {
                VStack(spacing: 12) {
                    // Select All for this store
                    HStack {
                        Button(action: {
                            toggleAllItems()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: allItemsChecked ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 16))
                                    .foregroundColor(allItemsChecked ? .green : .gray)
                                
                                Text(allItemsChecked ? "Unselect All" : "Select All")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    // Items list with product card design
                    LazyVStack(spacing: 8) {
                        ForEach(storeVisit.items, id: \.productId) { item in
                            ShoppingPlanProductRow(
                                item: item,
                                currency: currency,
                                product: getProduct(for: item),
                                storeName: storeVisit.storeName,
                                onToggle: {
                                    // Use a slight delay to prevent immediate scroll jumping
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                        shoppingListManager.toggleChecked(productId: item.productId)
                                    }
                                },
                                isChecked: shoppingListManager.isChecked(productId: item.productId)
                            )
                            .id("item_\(item.productId)") // Stable ID for each item
                            .padding(.horizontal, 8)
                        }
                    }
                    .padding(.bottom, 8)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }
}

struct ShoppingPlanProductRow: View {
    let item: ShoppingItem
    let currency: String
    let product: ProductWithMultipleStores?
    let storeName: String
    let onToggle: () -> Void
    let isChecked: Bool
    
    private func getCurrencySymbol(for currency: String) -> String {
        switch currency {
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        case "SEK": return "kr"
        case "AUD": return "A$"
        case "CAD": return "C$"
        case "CHF": return "CHF"
        default: return "$"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) { // Reduced from 16 to 12
            // Checkbox icon - smaller
            Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16)) // Reduced from 18 to 16
                .foregroundColor(isChecked ? .green : .gray)
            
            // Product image - smaller to match store logo size
            ProductImageView(
                imageUrl: product?.imageUrl,
                imageData: product?.imageData,
                placeholder: product?.iconName ?? "bag.fill",
                width: 44, // Reduced from 60 to 44 (same as store logo)
                height: 44 // Reduced from 60 to 44
            )
            
            // Product details - tighter spacing
            VStack(alignment: .leading, spacing: 1) { // Reduced from 2 to 1
                Text(item.productName)
                    .font(.system(size: 15, weight: .semibold)) // Reduced from 16 to 15
                    .foregroundColor(isChecked ? .secondary : .primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                if let brand = product?.brand {
                    Text(brand)
                        .font(.system(size: 11)) // Reduced from 14 to 11
                        .foregroundColor(isChecked ? .secondary : .secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            
            Spacer()
            
            // Price and Store - more compact
            VStack(alignment: .trailing, spacing: 4) { // Reduced from 8 to 4
                Text("\(getCurrencySymbol(for: currency))\(String(format: "%.2f", item.price))")
                    .font(.system(size: 15, weight: .semibold)) // Reduced from 16 to 15
                    .foregroundColor(isChecked ? .secondary : .primary)
                
                // Store name and allergy icon
                HStack(spacing: 4) {
                    Text(storeName)
                        .font(.system(size: 11, weight: .medium)) // Reduced from 12 to 11
                        .foregroundColor(isChecked ? .secondary : .primary)
                        .padding(.horizontal, 6) // Reduced from 8 to 6
                        .padding(.vertical, 2) // Reduced from 4 to 2
                        .background(isChecked ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                        .cornerRadius(4) // Reduced from 6 to 4
                    
                    // Allergy icon
                    if product?.containsUserAllergens == true {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding(.horizontal, 12) // Reduced from 16 to 12
        .padding(.vertical, 8) // Reduced from 12 to 8
        .background(isChecked ? Color.gray.opacity(0.2) : Color.appItemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12)) // Reduced from 16 to 12
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 1) // Reduced shadow
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
}

#Preview {
    ShoppingOptimizerView()
        .background(Color.appBackground)
}
