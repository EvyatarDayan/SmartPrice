//
//  UserShoppingListManager.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 10/09/2025.
//

import Foundation
import SwiftUI
import FirebaseAuth

class UserShoppingListManager: ObservableObject {
    static let shared = UserShoppingListManager()
    
    // Dictionary to store product IDs and their checked status in the shopping list
    @Published var shoppingListProductIds: [String: Bool] = [:]
    
    private let userDefaults = UserDefaults.standard
    private let shoppingListKeyPrefix = "userShoppingList"
    
    // Get user-specific storage key
    private var shoppingListKey: String {
        if let userId = Auth.auth().currentUser?.uid {
            return "\(shoppingListKeyPrefix)_\(userId)"
        } else {
            // Fallback for anonymous users (using device-specific identifier)
            return "\(shoppingListKeyPrefix)_anonymous"
        }
    }
    
    private init() {
        // Clear any old data format that might be causing issues
        clearOldDataFormat()
        loadShoppingList()
        debugPrintCurrentState()
        
        // Listen for authentication state changes
        setupAuthStateListener()
    }
    
    // MARK: - Authentication State Management
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.handleAuthStateChange(user: user)
            }
        }
    }
    
    private func handleAuthStateChange(user: FirebaseAuth.User?) {
        print("DEBUG: Auth state changed - User: \(user?.uid ?? "nil")")
        
        // Save current shopping list before switching users
        saveShoppingList()
        
        // Clear current shopping list
        shoppingListProductIds.removeAll()
        
        // Load shopping list for the new user (or anonymous)
        loadShoppingList()
        
        print("DEBUG: Switched to user-specific shopping list")
        debugPrintCurrentState()
    }
    
    // MARK: - Shopping List Management
    
    func addToShoppingList(productId: String) {
        print("DEBUG: Adding product to shopping list - ID: \(productId)")
        shoppingListProductIds[productId] = false // Add as unchecked
        print("DEBUG: Shopping list now has \(shoppingListProductIds.count) items")
        saveShoppingList()
    }
    
    func removeFromShoppingList(productId: String) {
        shoppingListProductIds.removeValue(forKey: productId)
        saveShoppingList()
    }
    
    func toggleShoppingList(productId: String) {
        if shoppingListProductIds[productId] != nil {
            // If already in shopping list, remove it
            shoppingListProductIds.removeValue(forKey: productId)
        } else {
            // If not in shopping list, add it (initially unchecked)
            shoppingListProductIds[productId] = false
        }
        saveShoppingList()
    }
    
    func isInShoppingList(productId: String) -> Bool {
        return shoppingListProductIds[productId] != nil
    }
    
    // MARK: - Checked Items Management
    
    func toggleChecked(productId: String) {
        if let isChecked = shoppingListProductIds[productId] {
            shoppingListProductIds[productId] = !isChecked
            saveShoppingList()
        }
    }
    
    func isChecked(productId: String) -> Bool {
        return shoppingListProductIds[productId] ?? false
    }
    
    func clearAllChecked() {
        for (productId, isChecked) in shoppingListProductIds {
            if isChecked {
                shoppingListProductIds[productId] = false
            }
        }
        saveShoppingList()
    }
    
    // MARK: - Data Persistence
    
    private func saveShoppingList() {
        // Convert dictionary to a format that can be saved to UserDefaults
        let shoppingListData = shoppingListProductIds.map { (key, value) in
            ["productId": key, "isChecked": value]
        }
        userDefaults.set(shoppingListData, forKey: shoppingListKey)
        
        // Force synchronization to ensure data is written to disk
        userDefaults.synchronize()
        
        print("DEBUG: Saved shopping list - Items: \(shoppingListProductIds.count)")
        print("DEBUG: Saved data: \(shoppingListData)")
    }
    
    private func loadShoppingList() {
        print("DEBUG: Attempting to load shopping list...")
        
        // Check if data exists in UserDefaults
        if let shoppingListData = userDefaults.array(forKey: shoppingListKey) as? [[String: Any]] {
            print("DEBUG: Found data in UserDefaults: \(shoppingListData)")
            
            var loadedItems: [String: Bool] = [:]
            for item in shoppingListData {
                if let productId = item["productId"] as? String,
                   let isChecked = item["isChecked"] as? Bool {
                    loadedItems[productId] = isChecked
                    print("DEBUG: Loaded item - ID: \(productId), Checked: \(isChecked)")
                } else {
                    print("DEBUG: Failed to parse item: \(item)")
                }
            }
            shoppingListProductIds = loadedItems
            print("DEBUG: Successfully loaded shopping list - Items: \(shoppingListProductIds.count)")
        } else {
            print("DEBUG: No data found in UserDefaults for key: \(shoppingListKey)")
            print("DEBUG: Available keys: \(userDefaults.dictionaryRepresentation().keys)")
        }
    }
    
    // MARK: - Helper Methods
    // Note: Product-related helper methods removed as we now use MultiStoreProductManager
    
    // MARK: - Debug Methods
    
    func clearAllData() {
        shoppingListProductIds.removeAll()
        saveShoppingList()
    }
    
    func getShoppingListCount() -> Int {
        return shoppingListProductIds.count
    }
    
    private func clearOldDataFormat() {
        // Remove any old data format that might be causing conflicts
        userDefaults.removeObject(forKey: "userCheckedItems")
        userDefaults.removeObject(forKey: "userShoppingList") // Old global key
        
        // Clear any old user-specific keys that might exist
        let allKeys = userDefaults.dictionaryRepresentation().keys
        for key in allKeys {
            if key.hasPrefix(shoppingListKeyPrefix) && key != shoppingListKey {
                userDefaults.removeObject(forKey: key)
                print("DEBUG: Cleared old user-specific key: \(key)")
            }
        }
        
        print("DEBUG: Cleared old data format")
    }
    
    // MARK: - Debug and Testing Methods
    
    func debugPrintCurrentState() {
        let currentUserId = Auth.auth().currentUser?.uid ?? "anonymous"
        print("DEBUG: Current shopping list state for user: \(currentUserId)")
        print("DEBUG: - Storage key: \(shoppingListKey)")
        print("DEBUG: - Total items: \(shoppingListProductIds.count)")
        for (productId, isChecked) in shoppingListProductIds {
            print("DEBUG: - Product ID: \(productId), Checked: \(isChecked)")
        }
        
        // Check what's actually in UserDefaults
        if let data = userDefaults.array(forKey: shoppingListKey) {
            print("DEBUG: Raw UserDefaults data: \(data)")
        } else {
            print("DEBUG: No data in UserDefaults for key: \(shoppingListKey)")
        }
    }
    
    func forceReloadFromUserDefaults() {
        print("DEBUG: Force reloading from UserDefaults...")
        loadShoppingList()
        debugPrintCurrentState()
    }
}
