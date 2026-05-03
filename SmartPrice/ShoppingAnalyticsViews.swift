//
//  ShoppingAnalyticsViews.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 18/09/2025.
//

import SwiftUI

struct StoreCostComparisonView: View {
    let storeAnalytics: [StoreShoppingCost]
    let currency: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            if storeAnalytics.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "cart.badge.plus")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                    
                    Text("Add items to your shopping list to see store cost comparison")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(storeAnalytics.enumerated()), id: \.element.storeName) { index, store in
                        SimpleStoreRow(store: store, currency: currency, isCheapest: index == 0)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.appItemBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}

struct SimpleStoreRow: View {
    let store: StoreShoppingCost
    let currency: String
    let isCheapest: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Text(store.storeName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isCheapest ? .green : .primary)
            
            Spacer()
            
            Text("\(currency) \(String(format: "%.2f", store.totalCost))")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isCheapest ? .green : .primary)
        }
        .padding(.vertical, 4)
    }
}

struct OptimalShoppingView: View {
    let optimalShopping: OptimalShoppingBreakdown?
    let currency: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            if let optimal = optimalShopping, !optimal.storeBreakdown.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Cost")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            Text("\(currency) \(String(format: "%.2f", optimal.totalCost))")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                        
                        if optimal.potentialSavings > 0 {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("You Save")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                
                                Text("\(currency) \(String(format: "%.2f", optimal.potentialSavings))")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Shopping Plan")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        ForEach(optimal.storeBreakdown, id: \.storeName) { store in
                            HStack {
                                Text(store.storeName)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text("\(store.items.count) items")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                
                                Text("\(currency) \(String(format: "%.2f", store.subtotal))")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "target")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                    
                    Text("Add items to your shopping list to see the best buy strategy")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
        .padding(16)
        .background(Color.appItemBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}

struct NutriScoreAnalyticsView: View {
    let nutriScoreBreakdown: NutriScoreBreakdown?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            if let breakdown = nutriScoreBreakdown, breakdown.totalItems > 0 {
                VStack(alignment: .leading, spacing: 16) {
                    // Health message
                    Text(breakdown.healthMessage)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    
                    // Pie chart breakdown
                    NutriScorePieChart(breakdown: breakdown)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "heart.text.square")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                    
                    Text("Add items to your shopping list to see health insights")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
        .padding(16)
        .background(Color.appItemBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}

struct ShoppingListSummaryView: View {
    let totalItems: Int
    let totalStores: Int
    
    var itemsText: String {
        if totalItems == 1 {
            return "1"
        } else {
            return "\(totalItems)"
        }
    }
    
    var body: some View {
        let _ = print("DEBUG: ShoppingListSummaryView - Received totalItems: \(totalItems), totalStores: \(totalStores)")
        HStack(spacing: 0) {
            // Left section - Items in List
            VStack(spacing: 2) {
                Text(itemsText)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Items in List")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            // Vertical divider
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(width: 1)
                .padding(.vertical, 8)
            
            // Right section - Stores Available
            VStack(spacing: 2) {
                Text("\(totalStores)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Stores Available")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 50)
        .padding(.horizontal, 16)
        .background(Color.appItemBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}

// MARK: - Savings Potential View
struct SavingsPotentialView: View {
    let singleStoreSavings: (cheapest: String, expensive: String, amount: Double)?
    let twoStoreSavings: (stores: [String], amount: Double)?
    let currency: String
    @ObservedObject private var navigationCoordinator = NavigationCoordinator.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // Single store savings
            if let single = singleStoreSavings {
                Button(action: {
                    navigationCoordinator.navigateToShoppingListWithStoreCount(1)
                }) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Save \(String(format: "%.2f", single.amount)) \(currency)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.green)
                        
                        HStack(spacing: 0) {
                            Text("By shopping at ")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            
                            Text(single.cheapest)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.blue)
                            
                            Text(" instead of ")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            
                            Text(single.expensive)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.blue)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 2-store savings
            if let twoStore = twoStoreSavings, twoStore.amount > 0 {
                if singleStoreSavings != nil {
                    Divider()
                        .padding(.vertical, 4)
                }
                
                Button(action: {
                    navigationCoordinator.navigateToShoppingListWithStoreCount(2)
                }) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Save \(String(format: "%.2f", twoStore.amount)) \(currency)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.green)
                        
                        if twoStore.stores.count >= 2 {
                            HStack(spacing: 0) {
                                Text("By splitting shopping between ")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                
                                Text(twoStore.stores[0])
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.blue)
                                
                                Text(" and ")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                
                                Text(twoStore.stores[1])
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                            .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.green.opacity(0.1), Color.green.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.3), lineWidth: 2)
        )
    }
}

// MARK: - Shopping Trends View
struct ShoppingTrendsView: View {
    let totalProducts: Int
    let inListCount: Int
    let averagePrice: Double
    
    var listPercentage: Double {
        guard totalProducts > 0 else { return 0 }
        return (Double(inListCount) / Double(totalProducts)) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // Metrics grid
            VStack(spacing: 12) {
                // Total products tracked
                HStack {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    Text("Products tracked")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(totalProducts)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Divider()
                
                // List percentage
                HStack {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("In shopping list")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(listPercentage))%")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Divider()
                
                // Average price
                HStack {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.green)
                        .frame(width: 24)
                    
                    Text("Avg. item price")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(String(format: "%.2f", averagePrice))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(20)
        .background(Color.appItemBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}

// MARK: - Unhealthy Products View
struct UnhealthyProductsView: View {
    let products: [ProductWithMultipleStores]
    let onProductTap: (ProductWithMultipleStores) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Spacer()
            }
            
            if products.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.green)
                    
                    Text("No unhealthy products in your list! 🎉")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(products, id: \.id) { product in
                        UnhealthyProductRow(product: product, onTap: {
                            onProductTap(product)
                        })
                    }
                }
            }
        }
        .padding(16)
        .background(Color.appItemBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}

struct UnhealthyProductRow: View {
    let product: ProductWithMultipleStores
    let onTap: () -> Void
    
    private func nutriScoreColor(for grade: String?) -> Color {
        switch grade?.uppercased() {
        case "D": return Color.red.opacity(0.8)
        case "E": return Color.red
        default: return Color.gray
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Product image
                ProductImageView(
                    imageUrl: product.imageUrl,
                    imageData: product.imageData,
                    placeholder: "GenericProduct",
                    width: 50,
                    height: 50
                )
                .cornerRadius(8)
                
                // Product info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(product.name)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        // Allergy icon
                        if product.containsUserAllergens {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                        }
                    }
                    
                    if let brand = product.brand, !brand.isEmpty {
                        Text(brand)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Nutri-Score badge
                VStack(spacing: 4) {
                    Text(product.nutriscoreGrade?.uppercased() ?? "?")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(nutriScoreColor(for: product.nutriscoreGrade))
                        .clipShape(Circle())
                    
                    Text("Nutri-Score")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color.appBackground)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
