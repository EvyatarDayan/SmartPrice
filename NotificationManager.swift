//
//  NotificationManager.swift
//  SmartPrice
//
//  Created by AI Assistant on 06/10/2025.
//

import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isNotificationEnabled = false
    @Published var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    
    private override init() {
        super.init()
        loadNotificationSettings()
        checkNotificationPermission()
    }
    
    // MARK: - Permission Management
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("DEBUG: Notification permission error: \(error)")
                    return
                }
                
                self?.isNotificationEnabled = granted
                self?.saveNotificationSettings()
                self?.checkNotificationPermission()
                
                if granted {
                    print("DEBUG: Notification permission granted")
                } else {
                    print("DEBUG: Notification permission denied")
                }
            }
        }
    }
    
    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.notificationPermissionStatus = settings.authorizationStatus
                
                switch settings.authorizationStatus {
                case .authorized, .provisional:
                    self?.isNotificationEnabled = true
                case .denied, .notDetermined:
                    self?.isNotificationEnabled = false
                @unknown default:
                    self?.isNotificationEnabled = false
                }
                
                print("DEBUG: Notification permission status: \(settings.authorizationStatus.rawValue)")
            }
        }
    }
    
    func openNotificationSettings() {
        if let settingsURL = URL(string: UIApplication.openNotificationSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
    
    // MARK: - Price Change Notifications
    
    func sendPriceChangeNotification(productName: String, oldPrice: Double, newPrice: Double, currency: String, store: String, productId: String? = nil) {
        print("DEBUG: 🔔 sendPriceChangeNotification called")
        print("DEBUG: 🔔 Product: \(productName), Store: \(store)")
        print("DEBUG: 🔔 Price change: \(oldPrice) -> \(newPrice) \(currency)")
        print("DEBUG: 🔔 Notifications enabled: \(isNotificationEnabled)")
        print("DEBUG: 🔔 Permission status: \(notificationPermissionStatus)")
        
        guard isNotificationEnabled else {
            print("DEBUG: ❌ Notifications disabled, skipping price change notification")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "💰 Price Change Alert"
        
        let priceChange = newPrice - oldPrice
        let changeDirection = priceChange > 0 ? "increased" : "decreased"
        let changeAmount = abs(priceChange)
        let changeEmoji = priceChange > 0 ? "📈" : "📉"
        
        content.body = "\(changeEmoji) \(productName) price \(changeDirection) by \(String(format: "%.2f", changeAmount)) \(currency) at \(store). Now \(String(format: "%.2f", newPrice)) \(currency)"
        content.sound = .default
        content.badge = 1
        
        // Add custom data for handling notification taps
        var userInfo: [String: Any] = [
            "type": "price_change",
            "product_name": productName,
            "old_price": oldPrice,
            "new_price": newPrice,
            "currency": currency,
            "store": store
        ]
        
        // Add product ID if available for deep linking
        if let productId = productId {
            userInfo["product_id"] = productId
        }
        
        content.userInfo = userInfo
        
        // Create request with unique identifier
        let identifier = "price_change_\(productName.replacingOccurrences(of: " ", with: "_"))_\(store)_\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("DEBUG: Failed to schedule price change notification: \(error)")
            } else {
                print("DEBUG: Price change notification scheduled for \(productName)")
            }
        }
    }
    
    func sendTestNotification() {
        guard isNotificationEnabled else {
            print("DEBUG: Notifications disabled, skipping test notification")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "SmartPrice Test"
        content.body = "Notifications are working! You'll receive alerts when prices change for items in your shopping list."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "test_notification", content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("DEBUG: Failed to send test notification: \(error)")
            } else {
                print("DEBUG: Test notification sent successfully")
            }
        }
    }
    
    // MARK: - Settings Persistence
    
    private func loadNotificationSettings() {
        isNotificationEnabled = UserDefaults.standard.bool(forKey: "isNotificationEnabled")
    }
    
    private func saveNotificationSettings() {
        UserDefaults.standard.set(isNotificationEnabled, forKey: "isNotificationEnabled")
    }
    
    func toggleNotifications(_ enabled: Bool) {
        if enabled && notificationPermissionStatus != .authorized {
            requestNotificationPermission()
        } else {
            isNotificationEnabled = enabled
            saveNotificationSettings()
        }
    }
    
    // MARK: - Notification Status Helpers
    
    var notificationStatusText: String {
        switch notificationPermissionStatus {
        case .authorized:
            return "Enabled"
        case .denied:
            return "Denied"
        case .notDetermined:
            return "Not Set"
        case .provisional:
            return "Provisional"
        @unknown default:
            return "Unknown"
        }
    }
    
    var notificationStatusColor: Color {
        switch notificationPermissionStatus {
        case .authorized:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        case .provisional:
            return .blue
        @unknown default:
            return .gray
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground with persistent options
        completionHandler([.alert, .sound, .badge, .banner])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        print("DEBUG: 🔔 User tapped notification with userInfo: \(userInfo)")
        
        if let type = userInfo["type"] as? String, type == "price_change" {
            print("DEBUG: 🔔 User tapped price change notification")
            
            // Handle deep linking to product view
            if let productId = userInfo["product_id"] as? String {
                print("DEBUG: 🔔 Navigating to product with ID: \(productId)")
                NotificationCenter.default.post(
                    name: NSNotification.Name("NavigateToProduct"),
                    object: nil,
                    userInfo: ["productId": productId]
                )
            } else if let productName = userInfo["product_name"] as? String {
                print("DEBUG: 🔔 Navigating to product with name: \(productName)")
                NotificationCenter.default.post(
                    name: NSNotification.Name("NavigateToProductByName"),
                    object: nil,
                    userInfo: ["productName": productName]
                )
            } else {
                // Fallback: navigate to shopping list
                print("DEBUG: 🔔 Navigating to shopping list as fallback")
                NotificationCenter.default.post(
                    name: NSNotification.Name("NavigateToShoppingList"),
                    object: nil
                )
            }
        }
        
        completionHandler()
    }
}
