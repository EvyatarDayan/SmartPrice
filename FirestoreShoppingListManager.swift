//
//  FirestoreShoppingListManager.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 15/09/2025.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class FirestoreShoppingListManager: ObservableObject {
    static let shared = FirestoreShoppingListManager()
    
    // Dictionary to store product IDs and their checked status in the shopping list
    @Published var shoppingListProductIds: [String: Bool] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let usersCollection = "users"
    private var listener: ListenerRegistration?
    private var currentUserId: String? // Track the current user to prevent duplicate listener setup
    
    private init() {
        // Don't setup listener here - it will be set up when user authenticates
        // via handleAuthStateChange method
        print("DEBUG: FirestoreShoppingListManager initialized with users collection approach")
    }
    
    deinit {
        listener?.remove()
    }
    
    // MARK: - Real-time Listener
    
    private func setupRealtimeListener() {
        guard let currentUser = Auth.auth().currentUser else {
            print("DEBUG: No authenticated user, skipping shopping list listener setup")
            return
        }
        
        print("DEBUG: Setting up real-time listener for user: \(currentUser.uid)")
        print("DEBUG: Current shopping list count before listener setup: \(shoppingListProductIds.count)")
        
        isLoading = true
        
        // Listen to the user's document in the users collection
        listener = db.collection(usersCollection)
            .document(currentUser.uid)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = "Error loading user shopping list: \(error.localizedDescription)"
                        print("DEBUG: Error loading user shopping list: \(error)")
                        return
                    }
                    
                    guard let document = snapshot, document.exists else {
                        print("DEBUG: User document not found for user \(currentUser.uid), creating new user document")
                        self?.createUserDocument(for: currentUser)
                        return
                    }
                    
                    // Parse the document data manually
                    guard let data = document.data() else {
                        print("DEBUG: No data found in user document")
                        self?.shoppingListProductIds = [:]
                        return
                    }
                    print("DEBUG: Loaded user document with data: \(data)")
                    
                    // Extract shopping list from document data
                    var newShoppingList: [String: Bool] = [:]
                    if let shoppingListData = data["shoppingList"] as? [String: Bool] {
                        print("DEBUG: Found shopping list data with \(shoppingListData.count) items")
                        for (productId, isChecked) in shoppingListData {
                            newShoppingList[productId] = isChecked
                            print("DEBUG: Loaded item - Product ID: \(productId), Checked: \(isChecked)")
                        }
                    } else {
                        print("DEBUG: No shopping list data found in user document")
                    }
                    
                    print("DEBUG: Setting shopping list with \(newShoppingList.count) items")
                    self?.shoppingListProductIds = newShoppingList
                    self?.errorMessage = nil
                    print("DEBUG: Successfully loaded \(newShoppingList.count) shopping list items from user document")
                }
            }
    }
    
    // MARK: - User Document Management
    
    private func createUserDocument(for user: FirebaseAuth.User) {
        print("DEBUG: Creating new user document for user: \(user.uid)")
        
        // Parse displayName into firstName and lastName if available
        let nameComponents = (user.displayName ?? "").components(separatedBy: " ")
        let firstName = nameComponents.first ?? ""
        let lastName = nameComponents.count > 1 ? nameComponents.dropFirst().joined(separator: " ") : ""
        
        let userData: [String: Any] = [
            "id": user.uid,
            "email": user.email ?? "",
            "firstName": firstName,
            "lastName": lastName,
            "profileImageUrl": "", // Will be updated when user uploads a profile image
            "createdAt": Timestamp(date: Date()),
            "lastUpdated": Timestamp(date: Date()),
            "shoppingList": [:]
        ]
        
        db.collection(usersCollection).document(user.uid).setData(userData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Error creating user document: \(error.localizedDescription)"
                    print("DEBUG: Error creating user document: \(error)")
                } else {
                    self?.errorMessage = nil
                    print("DEBUG: User document created successfully with new structure")
                    // The listener will pick up the new document and update the shopping list
                }
            }
        }
    }
    
    private func updateUserShoppingList() {
        guard let userId = currentUserId else {
            print("DEBUG: No current user ID for updating shopping list")
            return
        }
        
        print("DEBUG: Updating user shopping list for user: \(userId)")
        
        // Shopping list is already [String: Bool], so we can use it directly
        let shoppingListForFirestore: [String: Bool] = shoppingListProductIds
        
        db.collection(usersCollection).document(userId).updateData([
            "shoppingList": shoppingListForFirestore,
            "lastUpdated": FieldValue.serverTimestamp()
        ]) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Error updating shopping list: \(error.localizedDescription)"
                    print("DEBUG: Error updating shopping list: \(error)")
                } else {
                    self?.errorMessage = nil
                    print("DEBUG: Shopping list updated successfully in user document")
                }
            }
        }
    }
    
    // MARK: - Shopping List Management
    
    func addToShoppingList(productId: String) {
        guard let userId = currentUserId else {
            errorMessage = "User not authenticated to add to shopping list."
            print("DEBUG: FirestoreShoppingListManager - User not authenticated to add to shopping list.")
            return
        }
        
        // Prevent accidental addition of new products
        print("DEBUG: FirestoreShoppingListManager - Explicitly adding product \(productId) to shopping list for user \(userId)")
        
        if shoppingListProductIds[productId] != nil {
            print("DEBUG: FirestoreShoppingListManager - Product \(productId) already in shopping list.")
            return // Already in list
        }
        
        print("DEBUG: FirestoreShoppingListManager - Adding product \(productId) to shopping list for user \(userId)")
        shoppingListProductIds[productId] = false // Add as unchecked
        updateUserShoppingList()
    }
    
    func removeFromShoppingList(productId: String) {
        guard let userId = currentUserId else {
            errorMessage = "User not authenticated to remove from shopping list."
            print("DEBUG: FirestoreShoppingListManager - User not authenticated to remove from shopping list.")
            return
        }
        
        print("DEBUG: FirestoreShoppingListManager - Removing product \(productId) from shopping list for user \(userId)")
        shoppingListProductIds.removeValue(forKey: productId)
        updateUserShoppingList()
    }
    
    func toggleShoppingList(productId: String) {
        if shoppingListProductIds[productId] != nil {
            removeFromShoppingList(productId: productId)
        } else {
            addToShoppingList(productId: productId)
        }
    }
    
    func isInShoppingList(productId: String) -> Bool {
        return shoppingListProductIds[productId] != nil
    }
    
    // MARK: - Checked Items Management
    
    func toggleChecked(productId: String) {
        guard let userId = currentUserId else {
            errorMessage = "User not authenticated to toggle checked state."
            print("DEBUG: FirestoreShoppingListManager - User not authenticated to toggle checked state.")
            return
        }
        
        guard var isChecked = shoppingListProductIds[productId] else {
            print("DEBUG: FirestoreShoppingListManager - Product \(productId) not in shopping list, cannot toggle checked state.")
            return
        }
        
        let newCheckedState = !isChecked
        print("DEBUG: FirestoreShoppingListManager - Toggling product \(productId) checked state to \(newCheckedState) for user \(userId)")
        
        shoppingListProductIds[productId] = newCheckedState
        updateUserShoppingList()
    }
    
    func isChecked(productId: String) -> Bool {
        return shoppingListProductIds[productId] ?? false
    }
    
    func clearAllChecked() {
        guard let userId = currentUserId else {
            errorMessage = "User not authenticated to clear checked items."
            print("DEBUG: FirestoreShoppingListManager - User not authenticated to clear checked items.")
            return
        }
        
        print("DEBUG: FirestoreShoppingListManager - Clearing all checked items for user \(userId)")
        
        var hasChanges = false
        for (productId, isChecked) in shoppingListProductIds {
            if isChecked {
                shoppingListProductIds[productId] = false
                hasChanges = true
            }
        }
        
        if hasChanges {
            updateUserShoppingList()
        }
    }
    
    func deleteAllShoppingListItems() {
        guard let userId = currentUserId else {
            errorMessage = "User not authenticated to delete all shopping list items."
            print("DEBUG: FirestoreShoppingListManager - User not authenticated to delete all shopping list items.")
            return
        }
        
        print("DEBUG: FirestoreShoppingListManager - Deleting all shopping list items for user \(userId)")
        shoppingListProductIds.removeAll()
        updateUserShoppingList()
    }
    
    // MARK: - Helper Methods
    // Note: Product-related helper methods removed as we now use MultiStoreProductManager
    
    // MARK: - Authentication State Management
    
    func handleAuthStateChange(user: FirebaseAuth.User?) {
        let newUserId = user?.uid
        
        print("DEBUG: Auth state changed - New User: \(newUserId ?? "nil"), Current User: \(currentUserId ?? "nil")")
        print("DEBUG: Current shopping list count before change: \(shoppingListProductIds.count)")
        
        // Only remove listener and clear data if we're actually switching users
        if newUserId != currentUserId {
            print("DEBUG: User changed, removing listener and clearing data")
            listener?.remove()
            currentUserId = newUserId
            
            if user == nil {
                // User signed out - clear the shopping list
                shoppingListProductIds.removeAll()
                print("DEBUG: User signed out, cleared shopping list")
            } else {
                // User signed in - setup listener (this will load their shopping list)
                print("DEBUG: New user signed in, setting up listener")
                setupRealtimeListener()
            }
        } else if user != nil && listener == nil {
            // Same user but no listener - setup listener
            print("DEBUG: Same user but no listener, setting up listener")
            currentUserId = newUserId
            setupRealtimeListener()
        } else {
            print("DEBUG: No change needed - same user and listener exists")
        }
        
        print("DEBUG: Final shopping list count: \(shoppingListProductIds.count)")
        debugPrintCurrentState()
    }
    
    // MARK: - Debug Methods
    
    func debugPrintCurrentState() {
        let currentUserId = Auth.auth().currentUser?.uid ?? "anonymous"
        print("DEBUG: FirestoreShoppingListManager - Current shopping list state for user: \(currentUserId)")
        print("DEBUG: - Total items: \(shoppingListProductIds.count)")
        
        let uncheckedItems = shoppingListProductIds.filter { !$0.value }
        let checkedItems = shoppingListProductIds.filter { $0.value }
        
        print("DEBUG: - Unchecked items: \(uncheckedItems.count)")
        print("DEBUG: - Checked items: \(checkedItems.count)")
        
        print("DEBUG: - Unchecked item IDs: \(Array(uncheckedItems.keys))")
        print("DEBUG: - Checked item IDs: \(Array(checkedItems.keys))")
        
        for (productId, isChecked) in shoppingListProductIds {
            print("DEBUG: - Product ID: \(productId), Checked: \(isChecked)")
        }
    }
    
    // MARK: - Count Helpers
    
    /// Returns the count of unchecked items (active items in shopping list)
    var uncheckedItemsCount: Int {
        let uncheckedCount = shoppingListProductIds.values.filter { !$0 }.count
        print("DEBUG: FirestoreShoppingListManager - Total items: \(shoppingListProductIds.count), Unchecked items: \(uncheckedCount)")
        return uncheckedCount
    }
    
    /// Returns the count of all items in shopping list (both checked and unchecked)
    var totalItemsCount: Int {
        return shoppingListProductIds.count
    }
    
    /// Returns the count of unchecked items that exist in the current product database
    func activeShoppingListCount(products: [ProductWithMultipleStores]) -> Int {
        let productIds = Set(products.map { $0.id })
        let uncheckedItems = shoppingListProductIds.filter { !$0.value }
        
        print("DEBUG: ActiveShoppingListCount - Total unchecked items: \(uncheckedItems.count)")
        print("DEBUG: ActiveShoppingListCount - Available product IDs in DB: \(Array(productIds).sorted())")
        print("DEBUG: ActiveShoppingListCount - Unchecked shopping list IDs: \(Array(uncheckedItems.keys).sorted())")
        
        let activeItems = uncheckedItems.filter { item in
            // More precise matching - check exact match first, then base ID matches
            let exactMatch = productIds.contains(item.key)
            
            // For base product ID matching (remove store suffixes)
            let baseProductId = item.key.contains("_") ? String(item.key.split(separator: "_").first ?? "") : item.key
            let baseMatch = productIds.contains { $0.hasPrefix(baseProductId + "_") }
            
            let exists = exactMatch || baseMatch
            print("DEBUG: ActiveShoppingListCount - Item '\(item.key)' exists in DB: \(exists) (exact: \(exactMatch), base: \(baseMatch))")
            return exists
        }
        
        print("DEBUG: ActiveShoppingListCount - Final active items count: \(activeItems.count)")
        print("DEBUG: ActiveShoppingListCount - Active item IDs: \(Array(activeItems.keys).sorted())")
        
        return activeItems.count
    }
    
    /// Returns the count that matches exactly what's displayed in the shopping list view
    /// Only counts unchecked items that have matching products in the database
    func displayShoppingListCount(products: [ProductWithMultipleStores]) -> Int {
        let uncheckedItems = shoppingListProductIds.filter { !$0.value }
        
        print("DEBUG: DisplayShoppingListCount - Shopping list total items: \(shoppingListProductIds.count)")
        print("DEBUG: DisplayShoppingListCount - Unchecked items: \(uncheckedItems.count)")
        print("DEBUG: DisplayShoppingListCount - Available products: \(products.count)")
        
        // If no unchecked items, return 0
        if uncheckedItems.isEmpty {
            print("DEBUG: DisplayShoppingListCount - No unchecked items, returning 0")
            return 0
        }
        
        // Build a set of all base product IDs from the database
        let productBaseIds = Set(products.map { product -> String in
            let baseId = product.id.contains("_") ? String(product.id.split(separator: "_").first ?? "") : product.id
            return baseId
        })
        
        print("DEBUG: DisplayShoppingListCount - Product base IDs in DB: \(productBaseIds.sorted())")
        
        // Count items that have matching products in the database
        var displayCount = 0
        for item in uncheckedItems {
            let baseProductId = item.key.contains("_") ? String(item.key.split(separator: "_").first ?? "") : item.key
            
            if productBaseIds.contains(baseProductId) {
                displayCount += 1
                print("DEBUG: DisplayShoppingListCount - Counting item '\(item.key)' (base: '\(baseProductId)')")
            } else {
                print("DEBUG: DisplayShoppingListCount - Excluding item '\(item.key)' (base: '\(baseProductId)') - no matching product in DB")
            }
        }
        
        print("DEBUG: DisplayShoppingListCount - Final display count: \(displayCount)")
        return displayCount
    }
}