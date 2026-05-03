//
//  FirestoreProductDatabase.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 15/09/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import SwiftUI

class FirestoreProductDatabase: ObservableObject {
    static let shared = FirestoreProductDatabase()
    
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let productsCollection = "products"
    private var listener: ListenerRegistration?
    
    private init() {
        setupRealtimeListener()
    }
    
    deinit {
        listener?.remove()
    }
    
    // MARK: - Real-time Listener
    
    private func setupRealtimeListener() {
        isLoading = true
        
        listener = db.collection(productsCollection)
            .order(by: "lastUpdated", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = "Error fetching products: \(error.localizedDescription)"
                        print("DEBUG: Firestore error: \(error)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self?.errorMessage = "No products found"
                        return
                    }
                    
                    var newProducts: [Product] = []
                    for document in documents {
                        do {
                            let data = document.data()
                            
                            // Manually parse the document data to handle nutritional info
                            let product = Product(
                                id: data["id"] as? String,
                                name: data["name"] as? String ?? "Unknown",
                                brand: data["brand"] as? String,
                                category: data["category"] as? String ?? "Other",
                                barcode: data["barcode"] as? String,
                                store: data["store"] as? String ?? "Unknown",
                                price: data["price"] as? Double ?? 0.0,
                                date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
                                imageData: nil, // Will be loaded separately
                                imageUrl: data["imageUrl"] as? String,
                                iconName: data["iconName"] as? String,
                                isChecked: false,
                                isInShoppingList: false,
                                nutriscoreGrade: data["nutriscoreGrade"] as? String,
                                nutritionalInfo: self?.decodeNutritionalInfo(from: data["nutritionalInfo"] as? [String: Any]) ?? nil,
                                ingredients: data["ingredients"] as? String,
                                allergens: data["allergens"] as? String,
                                traces: data["traces"] as? String
                            )
                            newProducts.append(product)
                            print("DEBUG: Loaded product '\(product.name)' with Nutri-Score: \(product.nutriscoreGrade ?? "nil")")
                        } catch {
                            print("DEBUG: Error decoding product: \(error)")
                        }
                    }
                    
                    self?.products = newProducts
                    self?.errorMessage = nil
                    print("DEBUG: Loaded \(newProducts.count) products from Firestore")
                    print("DEBUG: FirestoreProductDatabase - Publishing \(newProducts.count) products to subscribers")
                }
            }
    }
    
    // MARK: - Product Management
    
    func addProduct(_ product: Product, imageData: Data? = nil) {
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "User must be authenticated to add products"
            return
        }
        
        print("DEBUG: 🔍 addProduct called for: '\(product.name)' (ID: \(product.id))")
        print("DEBUG: 🔍 Call stack: \(Thread.callStackSymbols.prefix(5).joined(separator: "\n"))")
        
        // Ensure product is not in shopping list when created
        guard !product.isInShoppingList else {
            errorMessage = "New products should not be in shopping list when created"
            print("DEBUG: ERROR - Product '\(product.name)' is marked as in shopping list when being created. This should not happen.")
            return
        }
        
        print("DEBUG: ========== ADDING PRODUCT ==========")
        print("DEBUG: Product ID: \(product.id)")
        print("DEBUG: Product name: \(product.name)")
        print("DEBUG: Store: \(product.store)")
        print("DEBUG: Price: \(product.price)")
        print("DEBUG: Date: \(product.date)")
        print("DEBUG: Brand: \(product.brand ?? "nil")")
        print("DEBUG: Category: \(product.category)")
        print("DEBUG: Barcode: \(product.barcode ?? "nil")")
        print("DEBUG: ImageData: \(imageData != nil ? "YES (\(imageData!.count) bytes)" : "NO")")
        print("DEBUG: 🚨 ALLERGEN DATA:")
        print("DEBUG: - Ingredients: '\(product.ingredients ?? "nil")'")
        print("DEBUG: - Allergens: '\(product.allergens ?? "nil")'")
        print("DEBUG: - Traces: '\(product.traces ?? "nil")'")
        
        // Check if product already exists in local array
        if let existingProduct = products.first(where: { $0.id == product.id }) {
            print("DEBUG: 🔍 EXISTING PRODUCT FOUND IN LOCAL ARRAY!")
            print("DEBUG: Existing price: \(existingProduct.price) -> New price: \(product.price)")
            print("DEBUG: Existing store: \(existingProduct.store)")
            print("DEBUG: Existing date: \(existingProduct.date)")
        } else {
            print("DEBUG: ✅ NEW PRODUCT - Not found in local array")
        }
        
        print("DEBUG: ======================================")
        
        // If there's image data, upload it to Firebase Storage first
        if let imageData = imageData {
            FirebaseStorageManager.shared.uploadProductImage(imageData, productId: product.id) { [weak self] result in
                switch result {
                case .success(let imageUrl):
                    print("DEBUG: Image upload successful for product '\(product.name)', URL: \(imageUrl)")
                    // Create FirestoreProduct with image URL
                    let firestoreProduct = FirestoreProduct(
                        from: product, 
                        addedBy: currentUser.uid, 
                        imageUrl: imageUrl,
                        imageStoragePath: "product_images/\(currentUser.uid)/\(product.id)_\(Int(Date().timeIntervalSince1970)).jpg"
                    )
                    self?.saveProductToFirestore(firestoreProduct)
                    
                case .failure(let error):
                    self?.errorMessage = "Error uploading image: \(error.localizedDescription)"
                    print("DEBUG: Error uploading image for product '\(product.name)': \(error)")
                    // Still save the product without image
                    let firestoreProduct = FirestoreProduct(from: product, addedBy: currentUser.uid)
                    self?.saveProductToFirestore(firestoreProduct)
                }
            }
        } else {
            // No image data, save product directly
            print("DEBUG: No image data provided for product '\(product.name)', saving without image")
            let firestoreProduct = FirestoreProduct(from: product, addedBy: currentUser.uid)
            saveProductToFirestore(firestoreProduct)
        }
    }
    
    private func encodeNutritionalInfo(_ nutritionalInfo: NutritionalInfo?) -> [String: Any] {
        guard let nutritionalInfo = nutritionalInfo else { return [:] }
        
        return [
            "energyKcal": nutritionalInfo.energyKcal ?? NSNull(),
            "fat": nutritionalInfo.fat ?? NSNull(),
            "saturatedFat": nutritionalInfo.saturatedFat ?? NSNull(),
            "sugars": nutritionalInfo.sugars ?? NSNull(),
            "salt": nutritionalInfo.salt ?? NSNull(),
            "proteins": nutritionalInfo.proteins ?? NSNull(),
            "carbohydrates": nutritionalInfo.carbohydrates ?? NSNull(),
            "fiber": nutritionalInfo.fiber ?? NSNull(),
            "nutritionScore": nutritionalInfo.nutritionScore ?? NSNull(),
            "novaGroup": nutritionalInfo.novaGroup ?? NSNull()
        ]
    }
    
    private func decodeNutritionalInfo(from data: [String: Any]?) -> NutritionalInfo? {
        guard let data = data, !data.isEmpty else { return nil }
        
        return NutritionalInfo(
            energyKcal: data["energyKcal"] as? Double,
            fat: data["fat"] as? Double,
            saturatedFat: data["saturatedFat"] as? Double,
            sugars: data["sugars"] as? Double,
            salt: data["salt"] as? Double,
            proteins: data["proteins"] as? Double,
            carbohydrates: data["carbohydrates"] as? Double,
            fiber: data["fiber"] as? Double,
            nutritionScore: data["nutritionScore"] as? Int,
            novaGroup: data["novaGroup"] as? Int
        )
    }
    
    private func saveProductToFirestore(_ firestoreProduct: FirestoreProduct) {
        guard let productId = firestoreProduct.id else {
            errorMessage = "Product ID is required"
            return
        }
        
        print("DEBUG: ========== SAVING TO FIRESTORE ==========")
        print("DEBUG: Firestore Product ID: \(productId)")
        print("DEBUG: Name: \(firestoreProduct.name)")
        print("DEBUG: Store: \(firestoreProduct.store)")
        print("DEBUG: Price: \(firestoreProduct.price)")
        print("DEBUG: Date: \(firestoreProduct.date)")
        print("DEBUG: 🚨 FIRESTORE ALLERGEN DATA:")
        print("DEBUG: - Ingredients: '\(firestoreProduct.ingredients ?? "nil")'")
        print("DEBUG: - Allergens: '\(firestoreProduct.allergens ?? "nil")'")
        print("DEBUG: - Traces: '\(firestoreProduct.traces ?? "nil")'")
        print("DEBUG: 🔍 CALL STACK TRACE:")
        print("DEBUG: - Thread: \(Thread.current)")
        print("DEBUG: ===========================================")
        
        // First, check if document already exists
        let docRef = db.collection(productsCollection).document(productId)
        docRef.getDocument { [weak self] (document, error) in
            if let document = document, document.exists {
                print("DEBUG: ⚠️ EXISTING DOCUMENT FOUND - Will update")
                if let existingPrice = document.data()?["price"] as? Double {
                    print("DEBUG: Old price: \(existingPrice) -> New price: \(firestoreProduct.price)")
                }
            } else {
                print("DEBUG: ✅ NEW DOCUMENT - Will create")
            }
            
            let productData: [String: Any] = [
                "id": productId,
                "name": firestoreProduct.name,
                "brand": firestoreProduct.brand ?? "",
                "category": firestoreProduct.category,
                "barcode": firestoreProduct.barcode ?? "",
                "store": firestoreProduct.store,
                "price": firestoreProduct.price,
                "date": firestoreProduct.date,
                "imageUrl": firestoreProduct.imageUrl ?? "",
                "imageStoragePath": firestoreProduct.imageStoragePath ?? "",
                "iconName": firestoreProduct.iconName ?? "",
                "addedBy": firestoreProduct.addedBy ?? "",
                "lastUpdated": firestoreProduct.lastUpdated,
                "nutriscoreGrade": firestoreProduct.nutriscoreGrade ?? "",
                "nutritionalInfo": self?.encodeNutritionalInfo(firestoreProduct.nutritionalInfo) ?? [:],
                "ingredients": firestoreProduct.ingredients ?? "",
                "allergens": firestoreProduct.allergens ?? "",
                "traces": firestoreProduct.traces ?? ""
            ]
            
            docRef.setData(productData, merge: true) { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = "Error adding/updating product: \(error.localizedDescription)"
                        print("DEBUG: ❌ Error adding/updating product: \(error)")
                    } else {
                        self?.errorMessage = nil
                        print("DEBUG: ✅ Product saved successfully to Firestore")
                        print("DEBUG: Final data - ID: \(productId), Name: \(firestoreProduct.name), Store: \(firestoreProduct.store), Price: \(firestoreProduct.price)")
                        
                        // Force update the local product array
                        if let existingIndex = self?.products.firstIndex(where: { $0.id == productId }) {
                            print("DEBUG: 🔄 Updating existing product at index \(existingIndex)")
                            // Update the existing product in the local array
                            self?.products[existingIndex] = Product(
                                id: productId,
                                name: firestoreProduct.name,
                                brand: firestoreProduct.brand,
                                category: firestoreProduct.category,
                                barcode: firestoreProduct.barcode,
                                store: firestoreProduct.store,
                                price: firestoreProduct.price,
                                date: firestoreProduct.date,
                                imageData: nil,
                                imageUrl: firestoreProduct.imageUrl,
                                iconName: firestoreProduct.iconName,
                                isChecked: self?.products[existingIndex].isChecked ?? false,
                                isInShoppingList: self?.products[existingIndex].isInShoppingList ?? false,
                                nutriscoreGrade: firestoreProduct.nutriscoreGrade,
                                nutritionalInfo: firestoreProduct.nutritionalInfo,
                                ingredients: firestoreProduct.ingredients,
                                allergens: firestoreProduct.allergens,
                                traces: firestoreProduct.traces
                            )
                        } else {
                            print("DEBUG: ➕ Product not found in local array, will be added by listener")
                        }
                    }
                }
            }
        }
    }
    
    func updateProduct(_ product: Product, imageData: Data? = nil) {
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "User must be authenticated to update products"
            return
        }
        
        let productId = product.id
        
        // If there's new image data, upload it to Firebase Storage first
        if let imageData = imageData {
            FirebaseStorageManager.shared.uploadProductImage(imageData, productId: product.id) { [weak self] result in
                switch result {
                case .success(let imageUrl):
                    // Create FirestoreProduct with new image URL
                    let firestoreProduct = FirestoreProduct(
                        from: product, 
                        addedBy: currentUser.uid, 
                        imageUrl: imageUrl,
                        imageStoragePath: "product_images/\(currentUser.uid)/\(product.id)_\(Int(Date().timeIntervalSince1970)).jpg"
                    )
                    self?.updateProductInFirestore(firestoreProduct)
                    
                case .failure(let error):
                    self?.errorMessage = "Error uploading image: \(error.localizedDescription)"
                    print("DEBUG: Error uploading image: \(error)")
                    // Still update the product without new image
                    let firestoreProduct = FirestoreProduct(from: product, addedBy: currentUser.uid)
                    self?.updateProductInFirestore(firestoreProduct)
                }
            }
        } else {
            // No new image data, update product directly
            let firestoreProduct = FirestoreProduct(from: product, addedBy: currentUser.uid)
            updateProductInFirestore(firestoreProduct)
        }
    }
    
    private func updateProductInFirestore(_ firestoreProduct: FirestoreProduct) {
        guard let productId = firestoreProduct.id else {
            errorMessage = "Product ID is required"
            return
        }
        
        let productData: [String: Any] = [
            "id": productId,
            "name": firestoreProduct.name,
            "brand": firestoreProduct.brand ?? "",
            "category": firestoreProduct.category,
            "barcode": firestoreProduct.barcode ?? "",
            "store": firestoreProduct.store,
            "price": firestoreProduct.price,
            "date": firestoreProduct.date,
            "imageUrl": firestoreProduct.imageUrl ?? "",
            "imageStoragePath": firestoreProduct.imageStoragePath ?? "",
            "iconName": firestoreProduct.iconName ?? "",
            "addedBy": firestoreProduct.addedBy ?? "",
            "lastUpdated": firestoreProduct.lastUpdated,
            "nutriscoreGrade": firestoreProduct.nutriscoreGrade ?? "",
            "nutritionalInfo": encodeNutritionalInfo(firestoreProduct.nutritionalInfo),
            "ingredients": firestoreProduct.ingredients ?? "",
            "allergens": firestoreProduct.allergens ?? "",
            "traces": firestoreProduct.traces ?? ""
        ]
        
        db.collection(productsCollection).document(productId).setData(productData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Error updating product: \(error.localizedDescription)"
                    print("DEBUG: Error updating product: \(error)")
                } else {
                    self?.errorMessage = nil
                    print("DEBUG: Product updated successfully in Firestore")
                }
            }
        }
    }
    
    func deleteProduct(_ product: Product) {
        let productId = product.id
        
        // First, get the product to check if it has an image to delete
        db.collection(productsCollection).document(productId).getDocument { [weak self] document, error in
            if let error = error {
                self?.errorMessage = "Error getting product for deletion: \(error.localizedDescription)"
                print("DEBUG: Error getting product for deletion: \(error)")
                return
            }
            
            guard let document = document, document.exists else {
                self?.errorMessage = "Product not found for deletion"
                print("DEBUG: Product not found for deletion")
                return
            }
            
            // Check if product has an image URL to delete from Storage
            if let imageUrl = document.data()?["imageUrl"] as? String, !imageUrl.isEmpty {
                FirebaseStorageManager.shared.deleteProductImage(urlString: imageUrl) { result in
                    switch result {
                    case .success:
                        print("DEBUG: Product image deleted from Storage")
                    case .failure(let error):
                        print("DEBUG: Error deleting product image from Storage: \(error)")
                        // Continue with product deletion even if image deletion fails
                    }
                }
            }
            
            // Delete the product document from Firestore
            self?.db.collection(self?.productsCollection ?? "").document(productId).delete { error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = "Error deleting product: \(error.localizedDescription)"
                        print("DEBUG: Error deleting product: \(error)")
                    } else {
                        self?.errorMessage = nil
                        print("DEBUG: Product deleted successfully from Firestore")
                    }
                }
            }
        }
    }
    
    // MARK: - Search and Filter
    
    func searchProducts(query: String) -> [Product] {
        if query.isEmpty {
            return products
        }
        
        return products.filter { product in
            product.name.localizedCaseInsensitiveContains(query) ||
            (product.brand?.localizedCaseInsensitiveContains(query) ?? false) ||
            product.category.localizedCaseInsensitiveContains(query) ||
            product.store.localizedCaseInsensitiveContains(query)
        }
    }
    
    func getProductsByStore(_ store: String) -> [Product] {
        return products.filter { $0.store == store }
    }
    
    func getProductsByCategory(_ category: String) -> [Product] {
        return products.filter { $0.category == category }
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Manual Refresh
    
    func refreshProducts() {
        print("DEBUG: 🔄 Manual refresh requested - restarting listener")
        
        // Remove existing listener
        listener?.remove()
        
        // Setup new listener (this will trigger a fresh fetch)
        setupRealtimeListener()
    }
    
    // MARK: - Migration from Local Storage
    
    func migrateFromLocalStorage() {
        // This method can be used to migrate existing local products to Firestore
        // For now, we'll keep it simple and let users re-add products
        print("DEBUG: Migration from local storage not implemented yet")
    }
}
