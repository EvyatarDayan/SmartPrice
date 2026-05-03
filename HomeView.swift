//
//  HomeView.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 10/09/2025.
//

import SwiftUI


struct HomeView: View {
    @StateObject private var firestoreDatabase = FirestoreProductDatabase.shared
    @StateObject private var multiStoreManager = MultiStoreProductManager.shared
    @StateObject private var shoppingListManager = FirestoreShoppingListManager.shared
    @ObservedObject private var navigationCoordinator = NavigationCoordinator.shared
    @State private var searchText = ""
    @State private var productToEdit: Product?
    @AppStorage("defaultCurrency") private var defaultCurrency: String = "EUR"
    
    var filteredMultiStoreProducts: [ProductWithMultipleStores] {
        var products = multiStoreManager.products
        
        // Apply search filter
        if !searchText.isEmpty {
            products = products.filter { product in
                product.name.localizedCaseInsensitiveContains(searchText) ||
                product.brand?.localizedCaseInsensitiveContains(searchText) == true ||
                product.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return products
    }
    
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with title
                VStack {
                    HStack {
                        Text("Products")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                }
                .background(Color.appBackground)
                
                // Search and Filter Bar
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search products...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .submitLabel(.done)
                            .onSubmit {
                                // Dismiss keyboard when Done is tapped
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.appSearchBackground)
                    .cornerRadius(10)
                    
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
                .background(Color.appBackground)
                
                // Product list
                if filteredMultiStoreProducts.isEmpty && !searchText.isEmpty {
                    // No results state
                    VStack(spacing: 16) {
                        Spacer()
                        
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("No results")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("Try adjusting your search or filter criteria")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.appBackground)
                } else {
                    List {
                        ForEach(filteredMultiStoreProducts) { multiStoreProduct in
                            let displayProduct = multiStoreProduct.toLegacyProduct()
                            ProductRowView(
                                product: displayProduct, 
                                defaultCurrency: defaultCurrency,
                                onTap: {
                                    productToEdit = displayProduct
                                }
                            )
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(Color.appBackground)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(item: $productToEdit) { product in
            EditProductView(
                product: product,
                onProductUpdated: { updatedProduct in
                    firestoreDatabase.updateProduct(updatedProduct, imageData: updatedProduct.imageData)
                }
            )
        }
        .onChange(of: navigationCoordinator.navigateToProductId) { productId in
            if let productId = productId {
                navigateToProduct(productId: productId)
            }
        }
        .onChange(of: navigationCoordinator.navigateToProductName) { productName in
            if let productName = productName {
                navigateToProductByName(productName: productName)
            }
        }
    }
    
    // MARK: - Navigation Helpers
    
    private func navigateToProduct(productId: String) {
        print("DEBUG: 🧭 HomeView - Navigating to product with ID: \(productId)")
        
        // Find the product by ID
        if let product = multiStoreManager.getProduct(by: productId) {
            // Convert to legacy Product for editing
            if let storePrice = product.storePrices.first {
                let legacyProduct = Product(
                    name: product.name,
                    brand: product.brand,
                    category: product.category,
                    barcode: product.barcode,
                    store: storePrice.store,
                    price: storePrice.price,
                    date: storePrice.date,
                    imageData: product.imageData,
                    imageUrl: product.imageUrl,
                    iconName: product.iconName,
                    isChecked: product.isChecked,
                    isInShoppingList: product.isInShoppingList,
                    nutriscoreGrade: product.nutriscoreGrade,
                    nutritionalInfo: product.nutritionalInfo
                )
                productToEdit = legacyProduct
            }
        }
        
        // Clear navigation state
        navigationCoordinator.clearNavigation()
    }
    
    private func navigateToProductByName(productName: String) {
        print("DEBUG: 🧭 HomeView - Navigating to product with name: \(productName)")
        
        // Find the product by name
        if let product = multiStoreManager.products.first(where: { $0.name.localizedCaseInsensitiveContains(productName) }) {
            // Convert to legacy Product for editing
            if let storePrice = product.storePrices.first {
                let legacyProduct = Product(
                    name: product.name,
                    brand: product.brand,
                    category: product.category,
                    barcode: product.barcode,
                    store: storePrice.store,
                    price: storePrice.price,
                    date: storePrice.date,
                    imageData: product.imageData,
                    imageUrl: product.imageUrl,
                    iconName: product.iconName,
                    isChecked: product.isChecked,
                    isInShoppingList: product.isInShoppingList,
                    nutriscoreGrade: product.nutriscoreGrade,
                    nutritionalInfo: product.nutritionalInfo
                )
                productToEdit = legacyProduct
            }
        }
        
        // Clear navigation state
        navigationCoordinator.clearNavigation()
    }
}

struct ProductRowView: View {
    let product: Product
    let defaultCurrency: String
    let onTap: () -> Void
    @StateObject private var shoppingListManager = FirestoreShoppingListManager.shared
    
    // Extract base product ID (remove store suffix if present)
    private var baseProductId: String {
        if product.id.contains("_") {
            return String(product.id.split(separator: "_").first ?? "")
        }
        return product.id
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Product image
            ProductImageView(
                imageUrl: product.imageUrl,
                imageData: product.imageData,
                placeholder: product.iconName ?? "bag.fill",
                width: 60,
                height: 60
            )
            
            // Product details
            VStack(alignment: .leading, spacing: 2) {
                Text(product.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                if let brand = product.brand {
                    Text(brand)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            
            Spacer()
            
            // Price and Shopping List Toggle
            VStack(alignment: .trailing, spacing: 8) {
                Text(product.formattedPrice(using: CurrencyManager(currency: defaultCurrency)))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                // Store name or Shopping cart icon with allergy indicator
                HStack(spacing: 4) {
                    if shoppingListManager.isInShoppingList(productId: baseProductId) {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(6)
                    } else {
                        Text(product.store)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                    }
                    
                    // Allergy icon
                    if product.containsUserAllergens {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.appItemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if shoppingListManager.isInShoppingList(productId: baseProductId) {
                Button("Remove from List") {
                    shoppingListManager.removeFromShoppingList(productId: baseProductId)
                }
                .tint(.red)
            } else {
                Button("Add to\nList") {
                    shoppingListManager.addToShoppingList(productId: baseProductId)
                }
                .tint(.green)
            }
        }
    }
}

#Preview {
    HomeView()
}
