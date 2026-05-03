//
//  SmartPriceApp.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 10/09/2025.
//

import SwiftUI
import FirebaseCore
import UserNotifications

@main
struct SmartPriceApp: App {
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @StateObject private var authManager = FirebaseAuthManager.shared
    @StateObject private var firstLaunchManager = FirstLaunchManager.shared
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var currencyManager = CurrencyManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var priceMonitoringService = PriceMonitoringService.shared
    @StateObject private var navigationCoordinator = NavigationCoordinator.shared
    @State private var showingLocationPermissionAlert = false
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Set up notification center delegate
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                MainTabView()
                    .preferredColorScheme(darkModeEnabled ? .dark : .light)
                    .onAppear {
                        handleFirstLaunch()
                    }
                    .alert("Welcome to SmartPrice!", isPresented: $showingLocationPermissionAlert) {
                        Button("Allow Location") {
                            firstLaunchManager.markLocationPermissionRequested()
                            currencyManager.isLocationBasedCurrencyEnabled = true
                            currencyManager.requestLocationPermissionAndUpdateCurrency()
                        }
                        Button("Not Now", role: .cancel) {
                            firstLaunchManager.markLocationPermissionRequested()
                        }
                    } message: {
                        Text("SmartPrice can automatically detect your location and set the appropriate currency (like SEK for Stockholm). This makes it easier to track prices in your local currency. You can change this later in Settings.")
                    }
            } else {
                AuthenticationView()
                    .preferredColorScheme(darkModeEnabled ? .dark : .light)
                    .onAppear {
                        handleFirstLaunch()
                    }
                    .alert("Welcome to SmartPrice!", isPresented: $showingLocationPermissionAlert) {
                        Button("Allow Location") {
                            firstLaunchManager.markLocationPermissionRequested()
                            currencyManager.isLocationBasedCurrencyEnabled = true
                            currencyManager.requestLocationPermissionAndUpdateCurrency()
                        }
                        Button("Not Now", role: .cancel) {
                            firstLaunchManager.markLocationPermissionRequested()
                        }
                    } message: {
                        Text("SmartPrice can automatically detect your location and set the appropriate currency (like SEK for Stockholm). This makes it easier to track prices in your local currency. You can change this later in Settings.")
                    }
            }
        }
    }
    
    private func handleFirstLaunch() {
        // Always enable location-based currency detection
        currencyManager.isLocationBasedCurrencyEnabled = true
        
        if firstLaunchManager.shouldRequestLocationPermission() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showingLocationPermissionAlert = true
            }
        }
        firstLaunchManager.markAsLaunched()
    }
}
