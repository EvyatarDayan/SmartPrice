//
//  NavigationCoordinator.swift
//  SmartPrice
//
//  Created by AI Assistant on 06/10/2025.
//

import Foundation
import SwiftUI
import Combine

class NavigationCoordinator: ObservableObject {
    static let shared = NavigationCoordinator()
    
    @Published var selectedTab: Int = 0
    @Published var navigateToProductId: String?
    @Published var navigateToProductName: String?
    @Published var shouldNavigateToShoppingList: Bool = false
    @Published var shoppingListStoreCount: Int?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        // Listen for navigation notifications
        NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToProduct"))
            .sink { [weak self] notification in
                if let productId = notification.userInfo?["productId"] as? String {
                    DispatchQueue.main.async {
                        self?.navigateToProduct(productId: productId)
                    }
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToProductByName"))
            .sink { [weak self] notification in
                if let productName = notification.userInfo?["productName"] as? String {
                    DispatchQueue.main.async {
                        self?.navigateToProductByName(productName: productName)
                    }
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToShoppingList"))
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.navigateToShoppingList()
                }
            }
            .store(in: &cancellables)
    }
    
    func navigateToProduct(productId: String) {
        print("DEBUG: 🧭 NavigationCoordinator - Navigating to product with ID: \(productId)")
        navigateToProductId = productId
        selectedTab = 0 // Home tab
    }
    
    func navigateToProductByName(productName: String) {
        print("DEBUG: 🧭 NavigationCoordinator - Navigating to product with name: \(productName)")
        navigateToProductName = productName
        selectedTab = 0 // Home tab
    }
    
    func navigateToShoppingList() {
        print("DEBUG: 🧭 NavigationCoordinator - Navigating to shopping list")
        shouldNavigateToShoppingList = true
        selectedTab = 3 // My List tab (updated index)
    }
    
    func navigateToShoppingListWithStoreCount(_ storeCount: Int) {
        print("DEBUG: 🧭 NavigationCoordinator - Navigating to shopping list with \(storeCount) store(s)")
        shoppingListStoreCount = storeCount
        shouldNavigateToShoppingList = true
        selectedTab = 3 // My List tab
    }
    
    func clearNavigation() {
        navigateToProductId = nil
        navigateToProductName = nil
        shouldNavigateToShoppingList = false
        shoppingListStoreCount = nil
    }
}
