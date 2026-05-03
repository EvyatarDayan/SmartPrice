//
//  MainTabView.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 10/09/2025.
//

import SwiftUI
import AVFoundation

struct MainTabView: View {
    @ObservedObject private var navigationCoordinator = NavigationCoordinator.shared
    
    var body: some View {
        TabView(selection: $navigationCoordinator.selectedTab) {
            // Home Tab - Dashboard
            DashboardView()
                .tabItem {
                    Image(systemName: navigationCoordinator.selectedTab == 0 ? "house.fill" : "house")
                    Text("Home")
                }
                .tag(0)
            
            // Products Tab
            HomeView()
                .tabItem {
                    Image(systemName: navigationCoordinator.selectedTab == 1 ? "shippingbox.fill" : "shippingbox")
                    Text("Products")
                }
                .tag(1)
            
            // Scan Tab - Direct camera scanner
            DirectScannerView(
                onScannerDismissed: {
                    // Go back to Home tab when scanner is dismissed
                    navigationCoordinator.selectedTab = 0
                }
            )
                .tabItem {
                    Image(systemName: navigationCoordinator.selectedTab == 2 ? "barcode.viewfinder" : "barcode.viewfinder")
                    Text("Scan")
                }
                .tag(2)
            
            // Favorites Tab
            FavoritesView()
                .tabItem {
                    Image(systemName: navigationCoordinator.selectedTab == 3 ? "cart.fill" : "cart")
                    Text("My List")
                }
                .tag(3)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Image(systemName: navigationCoordinator.selectedTab == 4 ? "gearshape.fill" : "gearshape")
                    Text("Settings")
                }
                .tag(4)
        }
        .accentColor(.blue)
        .safeAreaInset(edge: .bottom) {
            // Add extra padding above the tab bar
            Rectangle()
                .fill(Color.clear)
                .frame(height: 8)
        }
        .onAppear {
            // Configure tab bar appearance with better spacing
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            
            // Add subtle shadow for better separation
            appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// DirectScannerView - Opens camera scanner immediately
struct DirectScannerView: View {
    @State private var showingScanner = false
    @State private var scannedBarcode = ""
    @State private var showingAddProduct = false
    let onScannerDismissed: () -> Void
    
    var body: some View {
        // Empty view - scanner will open immediately
        Color.clear
            .onAppear {
                // Open scanner immediately when view appears
                checkCameraAndOpenScanner()
            }
        .sheet(isPresented: $showingScanner) {
            BarcodeScannerView(scannedCode: $scannedBarcode, isPresented: $showingScanner)
                .onDisappear {
                    // Open AddProductView with scanned barcode when scanner is dismissed
                    if !scannedBarcode.isEmpty {
                        showingAddProduct = true
                    } else {
                        // If no barcode was scanned, go back to previous view
                        onScannerDismissed()
                    }
                }
        }
        .sheet(isPresented: $showingAddProduct) {
            AddProductViewWithBarcode(
                initialBarcode: scannedBarcode,
                onProductAdded: { newProduct in
                    FirestoreProductDatabase.shared.addProduct(newProduct, imageData: newProduct.imageData)
                },
                onScanAgain: {
                    // Reset scanned barcode and open scanner again
                    scannedBarcode = ""
                    showingScanner = true
                }
            )
            .onDisappear {
                // Reset scanned barcode and go back to previous view
                scannedBarcode = ""
                onScannerDismissed()
            }
        }
    }
    
    private func checkCameraAndOpenScanner() {
        // Check if camera is available before showing scanner
        if AVCaptureDevice.authorizationStatus(for: .video) != .denied {
            // Add a small delay to ensure the view is fully loaded before presenting the scanner
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showingScanner = true
            }
        } else {
            // Show alert if camera is denied
            let alert = UIAlertController(
                title: "Camera Access Required",
                message: "Please enable camera access in Settings to scan barcodes.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(alert, animated: true)
            }
        }
    }
}

#Preview {
    MainTabView()
}
