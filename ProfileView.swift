//
//  ProfileView.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 10/09/2025.
//

import SwiftUI
import FirebaseFirestore

struct ProfileView: View {
    @StateObject private var authManager = FirebaseAuthManager.shared
    @State private var showingSignIn = false
    @State private var showingImagePicker = false
    @State private var showingAvatarSelection = false
    @State private var totalProducts = 6
    @State private var activeProducts = 6
    @State private var monthlyTotal = 100.68
    @State private var profileImage: UIImage?
    @State private var selectedAvatarName: String?
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Fixed Header with Logout Button (non-scrolling)
                VStack(spacing: 16) {
                    HStack {
                        Text("Edit Profile")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if authManager.isAuthenticated {
                            Button("Logout") {
                                authManager.signOut()
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.red)
                            .cornerRadius(8)
                        }
                    }
                    
//                    Text("Update your profile information")
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .background(Color.appBackground)
                
                // Scrollable Content
                ScrollView {
                    VStack(spacing: 0) {
                    
                    if authManager.isAuthenticated {
                        VStack(spacing: 60) {
                            // Profile Photo Section (matching SignUpView)
                            VStack(spacing: 16) {
                                Button(action: {
                                    showingImagePicker = true
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 120, height: 120)
                                        
                                    if let profileImage = profileImage {
                                        Image(uiImage: profileImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 120)
                                            .clipShape(Circle())
                                    } else if let selectedAvatarName = selectedAvatarName {
                                        Image(selectedAvatarName)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 120)
                                            .clipShape(Circle())
                                    } else {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 50))
                                            .foregroundColor(.white)
                                    }
                                    }
                                }
                                
                                HStack(spacing: 16) {
                                    Button("Library") {
                                        showingImagePicker = true
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(12)
                                    
                                    Button("Avatar") {
                                        showingAvatarSelection = true
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.top, 0)
                            
                            // Account Information Section (matching SignUpView)
                            VStack(alignment: .leading, spacing: 0) {
                                Text("ACCOUNT INFORMATION")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 16)
                                
                                VStack(spacing: 0) {
                                    // First Name and Last Name Row
                                    HStack(spacing: 0) {
                                        TextField("First Name", text: $firstName)
                                            .textFieldStyle(PlainTextFieldStyle())
                                            .autocapitalization(.words)
                                            .disableAutocorrection(true)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 16)
                                            .background(Color(.systemBackground))
                                        
                                        Rectangle()
                                            .fill(Color(.systemGray5))
                                            .frame(width: 1)
                                            .padding(.vertical, 8)
                                        
                                        TextField("Last Name", text: $lastName)
                                            .textFieldStyle(PlainTextFieldStyle())
                                            .autocapitalization(.words)
                                            .disableAutocorrection(true)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 16)
                                            .background(Color(.systemBackground))
                                    }
                                    
                                    Divider()
                                    
                                    // Email Field (read-only)
                                    HStack {
                                        Text(authManager.userEmail ?? "user@example.com")
                                            .textFieldStyle(PlainTextFieldStyle())
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 16)
                                            .background(Color(.systemGray6))
                                        
                                        Spacer()
                                    }
                                }
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.systemGray5), lineWidth: 1)
                                )
                            }
                            .padding(.horizontal, 20)
                            
                            // Save Profile Button (matching SignUpView button)
                            Button(action: saveProfile) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("Save Changes")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(isFormValid ? Color.blue : Color.gray.opacity(0.4))
                                .cornerRadius(12)
                            }
                            .disabled(isLoading || !isFormValid)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 100)
                        }
                    } else {
                        // Sign In Component (only show when not signed in)
                        HStack(spacing: 16) {
                            // User Icon
                            ZStack {
                                Circle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "person.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue)
                            }
                            
                            // Text Content
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Login to your account")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text("Access your data across devices")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Sign In Button
                            Button(action: {
                                showingSignIn = true
                            }) {
                                Text("Login")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color.appItemBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray5), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                    }
                }
                .background(Color.appBackground)
            }
            .background(Color.appBackground)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingSignIn) {
            SignInView()
        }
        .sheet(isPresented: $showingImagePicker) {
            ProfilePhotoSelector(image: $profileImage)
                .onChange(of: profileImage) { newImage in
                    if newImage != nil {
                        selectedAvatarName = nil // Clear avatar when custom image is selected
                    }
                }
        }
        .sheet(isPresented: $showingAvatarSelection) {
            AvatarSelectionView { avatarName in
                selectedAvatarName = avatarName
                profileImage = nil // Clear custom image when avatar is selected
            }
        }
        .onAppear {
            loadProfileData()
        }
    }
    
    // MARK: - Helper Methods
    
    private var isFormValid: Bool {
        return !firstName.isEmpty && !lastName.isEmpty
    }
    
    private func loadProfileData() {
        guard let userId = authManager.userUID else { return }
        
        // Parse the display name into first and last name
        if let displayName = authManager.userDisplayName {
            let nameComponents = displayName.components(separatedBy: " ")
            firstName = nameComponents.first ?? ""
            lastName = nameComponents.dropFirst().joined(separator: " ")
        }
        
        // Load user data from Firestore to get avatar selection
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { document, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("DEBUG: Error loading user document: \(error.localizedDescription)")
                    return
                }
                
                guard let document = document, document.exists,
                      let data = document.data() else {
                    print("DEBUG: User document not found")
                    return
                }
                
                // Load avatar selection if available
                if let avatarName = data["avatarName"] as? String, !avatarName.isEmpty {
                    selectedAvatarName = avatarName
                    print("DEBUG: Loaded avatar: \(avatarName)")
                }
                
                // Load first/last name from Firestore if available
                if let firstName = data["firstName"] as? String {
                    self.firstName = firstName
                }
                if let lastName = data["lastName"] as? String {
                    self.lastName = lastName
                }
            }
        }
        
        // Try to load profile image from Firebase Storage
        FirebaseStorageManager.shared.downloadProfileImage(userId: userId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let image):
                    self.profileImage = image
                    self.selectedAvatarName = nil // Clear avatar when custom image is found
                case .failure(_):
                    // No profile image found, keep avatar selection if any
                    self.profileImage = nil
                }
            }
        }
    }
    
    private func saveProfile() {
        guard !firstName.isEmpty && !lastName.isEmpty else { return }
        
        isLoading = true
        
        // Use the new method that handles both profile info and avatar
        authManager.updateUserProfile(firstName: firstName, lastName: lastName, avatarName: selectedAvatarName) { result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    print("Profile updated successfully")
                    self.isLoading = false
                case .failure(let error):
                    print("Error updating profile: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
        }
        
        // Handle profile image upload if there's a custom image
        if let profileImage = profileImage, let imageData = profileImage.jpegData(compressionQuality: 0.8) {
            // Upload custom profile image (this will clear the avatar selection)
            FirebaseStorageManager.shared.uploadProfileImage(imageData, userId: authManager.userUID ?? "") { result in
                switch result {
                case .success(let imageUrl):
                    print("Profile image uploaded: \(imageUrl)")
                    // Clear avatar selection when custom image is uploaded
                    self.authManager.updateUserAvatar(avatarName: nil) { _ in }
                case .failure(let error):
                    print("Error uploading profile image: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func updateFirestoreUserDocument() {
        // This would update the Firestore user document with new firstName/lastName
        // For now, we'll just update the display name in Firebase Auth
        isLoading = false
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
                                .background(Color.appItemBackground)
        .cornerRadius(12)
    }
}

struct QuickActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
                                .background(Color.appItemBackground)
            .cornerRadius(12)
        }
    }
}

struct ActivityRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct EditProfileView: View {
    @StateObject private var authManager = FirebaseAuthManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var userName: String = ""
    @State private var userEmail: String = ""
    @State private var userPhone: String = ""
    @State private var userID: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack {
                        HStack {
                            Text("Edit Profile")
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
                    
                    VStack(spacing: 24) {
                        // Personal Information Section
                        VStack(alignment: .leading, spacing: 0) {
                            Text("PERSONAL INFORMATION")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 8)
                            
                            VStack(spacing: 0) {
                                // Name
                                HStack {
                                    Text("Name")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    TextField("Enter name", text: $userName)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundColor(.blue)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.appFieldBackground)
                                
                                Divider()
                                    .padding(.leading, 20)
                                
                                // Email
                                HStack {
                                    Text("Email")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    TextField("Enter email", text: $userEmail)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundColor(.blue)
                                        .keyboardType(.emailAddress)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.appFieldBackground)
                                
                                Divider()
                                    .padding(.leading, 20)
                                
                                // Phone
                                HStack {
                                    Text("Phone")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    TextField("Enter phone", text: $userPhone)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundColor(.blue)
                                        .keyboardType(.phonePad)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.appFieldBackground)
                                
                                Divider()
                                    .padding(.leading, 20)
                                
                                // User ID
                                HStack {
                                    Text("User ID")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    TextField("Enter user ID", text: $userID)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundColor(.blue)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.appFieldBackground)
                            }
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray5), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Save Button
                        Button(action: {
                            // Update user information using Firebase
                            authManager.updateUserProfile(displayName: userName.isEmpty ? nil : userName, photoURL: nil) { result in
                                switch result {
                                case .success:
                                    presentationMode.wrappedValue.dismiss()
                                case .failure(let error):
                                    // Handle error if needed
                                    print("Error updating profile: \(error.localizedDescription)")
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                        }) {
                            Text("Save Changes")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .background(Color.appBackground)
            .navigationBarHidden(true)
        }
        .onAppear {
            // Load current user data from Firebase
            userName = authManager.userDisplayName ?? ""
            userEmail = authManager.userEmail ?? ""
            userPhone = "+972 222224444" // Default phone
            userID = authManager.userUID ?? "E33611C5" // Use Firebase UID or default
        }
    }
}

// MARK: - ProfilePhotoSelector
struct ProfilePhotoSelector: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ProfilePhotoSelector
        
        init(_ parent: ProfilePhotoSelector) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    ProfileView()
}
