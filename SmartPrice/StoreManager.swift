//
//  StoreManager.swift
//  SmartPrice
//
//  Manages enabled/disabled stores app-wide
//

import Foundation
import Combine

class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    @Published var enabledStores: Set<String> = []
    
    private let enabledStoresKey = "enabledStores"
    
    private init() {
        loadEnabledStores()
    }
    
    private func loadEnabledStores() {
        if let savedStores = UserDefaults.standard.array(forKey: enabledStoresKey) as? [String] {
            // Normalize all loaded store names
            enabledStores = Set(savedStores.map { normalizeStoreName($0) })
            print("DEBUG: StoreManager - Loaded enabled stores: \(enabledStores)")
        } else {
            // By default, enable all known stores
            enabledStores = Set(Store.knownStores.map { $0.name })
            saveEnabledStores()
            print("DEBUG: StoreManager - Initialized with all stores: \(enabledStores)")
        }
    }
    
    private func saveEnabledStores() {
        UserDefaults.standard.set(Array(enabledStores), forKey: enabledStoresKey)
    }
    
    func toggleStore(_ storeName: String) {
        let normalizedName = normalizeStoreName(storeName)
        print("DEBUG: StoreManager - Before toggle: \(enabledStores)")
        
        if enabledStores.contains(normalizedName) {
            enabledStores.remove(normalizedName)
            print("DEBUG: StoreManager - Disabled store: \(normalizedName)")
        } else {
            enabledStores.insert(normalizedName)
            print("DEBUG: StoreManager - Enabled store: \(normalizedName)")
        }
        
        print("DEBUG: StoreManager - After toggle: \(enabledStores)")
        saveEnabledStores()
        
        // Force update notification
        objectWillChange.send()
    }
    
    func isStoreEnabled(_ storeName: String) -> Bool {
        let normalizedName = normalizeStoreName(storeName)
        let isEnabled = enabledStores.contains(normalizedName)
        print("DEBUG: StoreManager - Checking if '\(storeName)' (normalized: '\(normalizedName)') is enabled: \(isEnabled)")
        return isEnabled
    }
    
    private func normalizeStoreName(_ name: String) -> String {
        // Normalize store names by trimming whitespace and standardizing case
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Map common variations to standard names
        let lowercased = trimmed.lowercased()
        switch lowercased {
        case "willys", "willis":
            return "Willys"
        case "coop":
            return "Coop"
        case "ica":
            return "ICA"
        case "hemköp", "hemkop":
            return "Hemköp"
        default:
            // Return with first letter capitalized
            return trimmed.prefix(1).uppercased() + trimmed.dropFirst()
        }
    }
    
    func enableAllStores() {
        enabledStores = Set(Store.knownStores.map { $0.name })
        saveEnabledStores()
    }
    
    func disableAllStores() {
        enabledStores.removeAll()
        saveEnabledStores()
    }
}

