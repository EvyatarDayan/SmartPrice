//
//  SettingsView.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 10/09/2025.
//

import SwiftUI
import FirebaseFirestore

struct SettingsView: View {
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @AppStorage("defaultCurrency") private var defaultCurrency: String = "EUR"
    @StateObject private var authManager = FirebaseAuthManager.shared
    @ObservedObject var currencyManager = CurrencyManager.shared
    @ObservedObject var locationManager = LocationManager.shared
    @ObservedObject var notificationManager = NotificationManager.shared
    @State private var showingLocationPermissionAlert = false
    @State private var showingProfileEdit = false
    @State private var userFirstName: String = ""
    @State private var userLastName: String = ""
    @State private var userProfileImage: UIImage?
    @State private var selectedAvatarName: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Fixed Header
                VStack {
                    HStack {
                        Text("Settings")
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
                
                // Scrollable Content
                ScrollView {
                    VStack(spacing: 24) {
                        // PROFILE Section
                        VStack(alignment: .leading, spacing: 0) {
                            Text("PROFILE")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 8)
                            
                            Button(action: {
                                showingProfileEdit = true
                            }) {
                                HStack(spacing: 16) {
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
                                                .font(.system(size: 40))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                                    
                                    // User info
                                    VStack(alignment: .leading, spacing: 4) {
                                        if !userFirstName.isEmpty || !userLastName.isEmpty {
                                            Text("\(userFirstName) \(userLastName)".trimmingCharacters(in: .whitespaces))
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(.primary)
                                        } else {
                                            Text(authManager.currentUser?.email?.components(separatedBy: "@").first ?? "User")
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(.primary)
                                        }
                                        
                                        Text(authManager.currentUser?.email ?? "")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                    
                                    // Edit indicator
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color.appFieldBackground)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray5), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // PREFERENCES Section
                        VStack(alignment: .leading, spacing: 0) {
                            Text("PREFERENCES")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 8)
                            
                            VStack(spacing: 0) {
                                // Dark Mode
                                HStack {
                                    Text("Dark Mode")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $darkModeEnabled)
                                        .labelsHidden()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.appItemBackground)
                            }
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray5), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // LOCATION Section
                        VStack(alignment: .leading, spacing: 0) {
                            Text("LOCATION")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 8)
                            
                            VStack(spacing: 0) {
                                // Current Location
                                HStack {
                                    Text("Location")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 2) {
                                        if locationManager.isLoading {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        } else if let errorMessage = locationManager.errorMessage {
                                            // Show only the error message when there's an error
                                            Text(errorMessage)
                                                .font(.body)
                                                .foregroundColor(.red)
                                                .multilineTextAlignment(.trailing)
                                        } else {
                                            // Show location only when there's no error
                                            Text(locationManager.getCurrentLocationString())
                                                .font(.body)
                                                .foregroundColor(.primary)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.appItemBackground)
                                
                                
                                // Currency - Read-only display
                                HStack {
                                    Text("Currency")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 8) {
                                        Text(CurrencyManager.shared.flagForCurrency(defaultCurrency))
                                            .font(.system(size: 16))
                                        
                                        Text(defaultCurrency)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.appItemBackground)
                            }
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray5), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // SUPPORT Section
                        VStack(alignment: .leading, spacing: 0) {
                            Text("SUPPORT")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 8)
                            
                            VStack(spacing: 0) {
                                // Help & Support
                                HStack {
                                    Text("Help & Support")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.appItemBackground)
                                
                                Divider()
                                    .padding(.leading, 20)
                                
                                // Terms & Privacy
                                HStack {
                                    Text("Terms & Privacy")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.appItemBackground)
                                
                                Divider()
                                    .padding(.leading, 20)
                                
                                // About
                                HStack {
                                    Text("About")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.appItemBackground)
                            }
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray5), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // NOTIFICATIONS Section
                        VStack(alignment: .leading, spacing: 0) {
                            Text("NOTIFICATIONS")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 8)
                            
                            VStack(spacing: 0) {
                                // Price Alerts Toggle
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Price Alerts")
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        
                                        Text("Get notified when prices change for items in your shopping list")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $notificationManager.isNotificationEnabled)
                                        .labelsHidden()
                                        .onChange(of: notificationManager.isNotificationEnabled) { enabled in
                                            notificationManager.toggleNotifications(enabled)
                                        }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.appItemBackground)
                                
                            }
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray5), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // STORE MANAGEMENT Section
                        VStack(alignment: .leading, spacing: 0) {
                            Text("STORE MANAGEMENT")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 8)
                            
                            VStack(spacing: 0) {
                                ForEach(Array(Store.knownStores.enumerated()), id: \.element.id) { index, store in
                                    StoreToggleRow(store: store)
                                    
                                    if index < Store.knownStores.count - 1 {
                                        Divider()
                                            .padding(.leading, 80)
                                    }
                                }
                            }
                            .background(Color.appItemBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray5), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // ALLERGY & INGREDIENT ALERTS Section
                        VStack(alignment: .leading, spacing: 0) {
                            Text("ALLERGY & INGREDIENT ALERTS")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 8)
                            
                            AllergySettingsView()
                        }
                        .padding(.horizontal, 20)
                        
                        .padding(.bottom, 100) // Space for tab bar
                    }
                    .padding(.top, 20)
                }
            }
            .background(Color.appBackground)
            .navigationBarHidden(true)
        }
        .onAppear {
            loadUserProfile()
            // Always enable location-based currency detection in the background
            currencyManager.isLocationBasedCurrencyEnabled = true
        }
        .sheet(isPresented: $showingProfileEdit) {
            ProfileView()
        }
        .alert("Location Permission Required", isPresented: $showingLocationPermissionAlert) {
            Button("Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("Cancel", role: .cancel) {
                currencyManager.isLocationBasedCurrencyEnabled = false
            }
        } message: {
            Text("Location access is required to automatically detect your currency. Please enable location access in Settings to use this feature.")
        }
    }
    
    private func loadUserProfile() {
        guard let userId = authManager.currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data() ?? [:]
                
                DispatchQueue.main.async {
                    userFirstName = data["firstName"] as? String ?? ""
                    userLastName = data["lastName"] as? String ?? ""
                    selectedAvatarName = data["avatarName"] as? String
                    
                    // Load profile image if available
                    if let profileImageUrl = data["profileImageUrl"] as? String, !profileImageUrl.isEmpty {
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
    }
}

struct StoreToggleRow: View {
    let store: Store
    @ObservedObject private var storeManager = StoreManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Store logo
            if let image = UIImage(named: store.logoName) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            } else {
                Image(systemName: "storefront")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            
            // Store name
            Text(store.name)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: Binding(
                get: { storeManager.isStoreEnabled(store.name) },
                set: { _ in storeManager.toggleStore(store.name) }
            ))
            .labelsHidden()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

#Preview {
    SettingsView()
}
