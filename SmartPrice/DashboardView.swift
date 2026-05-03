import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

struct DashboardView: View {
    @StateObject private var firestoreDatabase = FirestoreProductDatabase.shared
    @StateObject private var authManager = FirebaseAuthManager.shared
    @StateObject private var analyticsManager = ShoppingAnalyticsManager.shared
    @StateObject private var multiStoreManager = MultiStoreProductManager.shared
    @StateObject private var shoppingListManager = FirestoreShoppingListManager.shared
    @AppStorage("defaultCurrency") private var defaultCurrency: String = "EUR"
    
    @State private var userFirstName: String = ""
    @State private var userLastName: String = ""
    @State private var userProfileImage: UIImage?
    @State private var selectedAvatarName: String?
    @State private var productToEdit: Product?
    @State private var unhealthyProducts: [ProductWithMultipleStores] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Fixed Header Section - Profile
                VStack(alignment: .leading, spacing: 16) {
                    // Profile section
                    HStack(spacing: 12) {
                        // Profile photo
                        Group {
                            if let profileImage = userProfileImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else if let avatarName = selectedAvatarName {
                                Image(avatarName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                        
                        // Profile info
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Hello, \(userFirstName.isEmpty ? "User" : userFirstName)!")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("Welcome back to SmartPrice")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                }
                .background(Color.appBackground)
                
                // Fixed Summary Section - Items & Stores
                VStack(spacing: 0) {
                    ShoppingListSummaryView(
                        totalItems: ShoppingOptimizer.shared.shoppingListItemCount,
                        totalStores: analyticsManager.storeAnalytics.count
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
                .background(Color.appBackground)
                
                // Scrollable Analytics Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Savings Potential Section
                        if analyticsManager.storeAnalytics.count > 1 {
                            let singleStoreSavings = calculateSingleStoreSavings()
                            let twoStoreSavings = calculateTwoStoreSavings()
                            
                            if singleStoreSavings != nil || twoStoreSavings != nil {
                                VStack(alignment: .leading, spacing: 12) {
                                    // Title above section
                                    HStack {
                                        Image(systemName: "dollarsign.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.green)
                                        
                                        Text("Savings Potential")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 20)
                                    
                                    SavingsPotentialView(
                                        singleStoreSavings: singleStoreSavings,
                                        twoStoreSavings: twoStoreSavings,
                                        currency: defaultCurrency
                                    )
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        
                        // Store cost comparison
                        if !analyticsManager.storeAnalytics.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                // Title above section
                                HStack {
                                    Image(systemName: "chart.bar.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.blue)
                                    
                                    Text("Cost By Store")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                
                                StoreCostComparisonView(
                                    storeAnalytics: analyticsManager.storeAnalytics,
                                    currency: defaultCurrency
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Nutri-Score analytics
                        if shoppingListManager.displayShoppingListCount(products: multiStoreManager.products) > 0 {
                            VStack(alignment: .leading, spacing: 12) {
                                // Title above section
                                HStack {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.red)
                                    
                                    Text("Health Score")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                
                                NutriScoreAnalyticsView(
                                    nutriScoreBreakdown: analyticsManager.nutriScoreBreakdown
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Shopping Trends Section
                        if shoppingListManager.displayShoppingListCount(products: multiStoreManager.products) > 0 {
                            VStack(alignment: .leading, spacing: 12) {
                                // Title above section
                                HStack {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.system(size: 22))
                                        .foregroundColor(.blue)
                                    
                                    Text("Shopping Insights")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                
                                ShoppingTrendsView(
                                    totalProducts: multiStoreManager.products.count,
                                    inListCount: shoppingListManager.displayShoppingListCount(products: multiStoreManager.products),
                                    averagePrice: calculateAveragePrice()
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Unhealthy Products Section
                        if !unhealthyProducts.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                // Title above section
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.red)
                                    
                                    Text("Unhealthy Products")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                
                                UnhealthyProductsView(
                                    products: unhealthyProducts,
                                    onProductTap: { product in
                                        openProductView(product)
                                    }
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        Spacer(minLength: 100) // Bottom padding for tab bar
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 30)
                }
                .background(Color.appBackground)
            }
            .navigationBarHidden(true)
        }
        .sheet(item: $productToEdit) { product in
            EditProductView(
                product: product,
                onProductUpdated: { _ in
                    // Product is automatically updated via Firestore listener
                    productToEdit = nil
                }
            )
        }
        .onAppear {
            loadUserProfile()
            // Add a small delay to ensure data is loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                loadUnhealthyProducts()
            }
            // Also try immediately in case data is already loaded
            loadUnhealthyProducts()
            // Debug: Print current shopping list state
            shoppingListManager.debugPrintCurrentState()
        }
        .onChange(of: NavigationCoordinator.shared.selectedTab) { newTab in
            // Reload unhealthy products when returning to the dashboard tab
            if newTab == 0 {
                loadUnhealthyProducts()
            }
        }
        .onReceive(multiStoreManager.$products) { _ in
            loadUnhealthyProducts()
        }
        .onReceive(shoppingListManager.$shoppingListProductIds) { _ in
            loadUnhealthyProducts()
        }
    }
    
    private func calculateAveragePrice() -> Double {
        let shoppingListProducts = multiStoreManager.products.filter { product in
            shoppingListManager.shoppingListProductIds.keys.contains(product.id)
        }
        
        guard !shoppingListProducts.isEmpty else { return 0 }
        
        let totalPrice = shoppingListProducts.reduce(into: 0.0) { sum, product in
            sum += product.lowestPrice
        }
        
        return totalPrice / Double(shoppingListProducts.count)
    }
    
    private func calculateSingleStoreSavings() -> (cheapest: String, expensive: String, amount: Double)? {
        guard let cheapestStore = analyticsManager.storeAnalytics.min(by: { $0.totalCost < $1.totalCost }),
              let mostExpensiveStore = analyticsManager.storeAnalytics.max(by: { $0.totalCost < $1.totalCost }),
              analyticsManager.storeAnalytics.count > 1 else {
            return nil
        }
        
        let savings = mostExpensiveStore.totalCost - cheapestStore.totalCost
        guard savings > 0 else { return nil }
        
        return (cheapest: cheapestStore.storeName, expensive: mostExpensiveStore.storeName, amount: savings)
    }
    
    private func calculateTwoStoreSavings() -> (stores: [String], amount: Double)? {
        guard analyticsManager.storeAnalytics.count >= 2,
              let cheapestStore = analyticsManager.storeAnalytics.min(by: { $0.totalCost < $1.totalCost }) else {
            return nil
        }
        
        // Get shopping list products
        let shoppingListProducts = multiStoreManager.products.filter { product in
            shoppingListManager.shoppingListProductIds.keys.contains(product.id)
        }
        
        guard !shoppingListProducts.isEmpty else { return nil }
        
        // Calculate best 2-store combination
        let allStores = Set(shoppingListProducts.flatMap { $0.storePrices.map { $0.store } }).sorted()
        
        guard allStores.count >= 2 else { return nil }
        
        var bestCombination: (stores: [String], cost: Double)?
        
        // Try all 2-store combinations
        for i in 0..<allStores.count {
            for j in (i+1)..<allStores.count {
                let store1 = allStores[i]
                let store2 = allStores[j]
                
                var totalCost: Double = 0
                var canBuyAll = true
                
                for product in shoppingListProducts {
                    // Find cheapest price between these two stores
                    let pricesInStores = product.storePrices.filter { $0.store == store1 || $0.store == store2 }
                    
                    if let cheapestPrice = pricesInStores.min(by: { $0.price < $1.price }) {
                        totalCost += cheapestPrice.price
                    } else {
                        canBuyAll = false
                        break
                    }
                }
                
                if canBuyAll {
                    if bestCombination == nil || totalCost < bestCombination!.cost {
                        bestCombination = (stores: [store1, store2], cost: totalCost)
                    }
                }
            }
        }
        
        guard let best = bestCombination else { return nil }
        
        let savings = cheapestStore.totalCost - best.cost
        guard savings > 0 else { return nil }
        
        return (stores: best.stores, amount: savings)
    }
    
    private func loadUserProfile() {
        guard let userId = authManager.currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("DEBUG: Error loading user profile: \(error)")
                return
            }
            
            guard let data = document?.data() else { return }
            
            DispatchQueue.main.async {
                userFirstName = data["firstName"] as? String ?? ""
                userLastName = data["lastName"] as? String ?? ""
                selectedAvatarName = data["avatarName"] as? String
                
                if let profileImageUrl = data["profileImageUrl"] as? String, !profileImageUrl.isEmpty {
                    // Load from URL
                    FirebaseStorageManager.shared.downloadProductImage(from: profileImageUrl) { result in
                        switch result {
                        case .success(let data):
                            DispatchQueue.main.async {
                                userProfileImage = UIImage(data: data)
                            }
                        case .failure:
                            print("DEBUG: Failed to load profile image from URL")
                        }
                    }
                }
            }
        }
    }
    
    private func loadUnhealthyProducts() {
        print("DEBUG: 🏠 DashboardView - Loading unhealthy products...")
        print("DEBUG: 🏠 DashboardView - Total products: \(multiStoreManager.products.count)")
        print("DEBUG: 🏠 DashboardView - Shopping list items: \(shoppingListManager.shoppingListProductIds.count)")
        
        // Filter for D and E-rated products that are in the user's shopping list
        let unhealthy = multiStoreManager.products.filter { product in
            let grade = product.nutriscoreGrade?.uppercased()
            let hasUnhealthyGrade = (grade == "D" || grade == "E")
            
            // Check if product is in shopping list
            let inShoppingList = shoppingListManager.shoppingListProductIds.keys.contains(product.id)
            
            if hasUnhealthyGrade && inShoppingList {
                print("DEBUG: 🏠 DashboardView - Found unhealthy product: \(product.name) (Grade: \(grade ?? "?"))")
            }
            
            return hasUnhealthyGrade && inShoppingList
        }
        
        print("DEBUG: 🏠 DashboardView - Found \(unhealthy.count) unhealthy products")
        
        DispatchQueue.main.async {
            self.unhealthyProducts = unhealthy
        }
    }
    
    private func openProductView(_ product: ProductWithMultipleStores) {
        // Convert ProductWithMultipleStores to legacy Product for editing
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
                nutritionalInfo: product.nutritionalInfo,
                ingredients: product.ingredients,
                allergens: product.allergens,
                traces: product.traces
            )
            productToEdit = legacyProduct
        }
    }
}

#Preview {
    DashboardView()
}