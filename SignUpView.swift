//
//  SignUpView.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 10/09/2025.
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var authManager = FirebaseAuthManager.shared
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var showingImagePicker = false
    @State private var showingPhotoLibrary = false
    @State private var showingAvatarSelection = false
    @State private var profileImage: UIImage?
    @State private var selectedAvatarName: String?
    @State private var showPasswordText = false
    @State private var showConfirmPasswordText = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        Text("Create Account")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Sign up to start")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, 20)
                    
                    VStack(spacing: 32) {
                        // Profile Photo Section
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
                                    showingPhotoLibrary = true
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
                        
                        // Account Information Section
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
                                        .background(Color(UIColor { traitCollection in
                                            traitCollection.userInterfaceStyle == .dark ? UIColor.black : UIColor.white
                                        }))
                                    
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
                                        .background(Color(UIColor { traitCollection in
                                            traitCollection.userInterfaceStyle == .dark ? UIColor.black : UIColor.white
                                        }))
                                }
                                
                                Divider()
                                
                                // Email Field
                                TextField("Email", text: $email)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(Color(UIColor { traitCollection in
                                            traitCollection.userInterfaceStyle == .dark ? UIColor.black : UIColor.white
                                        }))
                                
                                Divider()
                                
                                // Password Field
                                HStack {
                                    Group {
                                        if showPasswordText {
                                            TextField("Password", text: $password)
                                        } else {
                                            SecureField("Password", text: $password)
                                        }
                                    }
                                    .textFieldStyle(PlainTextFieldStyle())
                                    
                                    Button(action: {
                                        showPasswordText.toggle()
                                    }) {
                                        Image(systemName: showPasswordText ? "eye.slash" : "eye")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color(UIColor { traitCollection in
                                            traitCollection.userInterfaceStyle == .dark ? UIColor.black : UIColor.white
                                        }))
                                
                                Divider()
                                
                                // Re-enter Password Field
                                HStack {
                                    Group {
                                        if showConfirmPasswordText {
                                            TextField("Re-enter Password", text: $confirmPassword)
                                        } else {
                                            SecureField("Re-enter Password", text: $confirmPassword)
                                        }
                                    }
                                    .textFieldStyle(PlainTextFieldStyle())
                                    
                                    Button(action: {
                                        showConfirmPasswordText.toggle()
                                    }) {
                                        Image(systemName: showConfirmPasswordText ? "eye.slash" : "eye")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color(UIColor { traitCollection in
                                            traitCollection.userInterfaceStyle == .dark ? UIColor.black : UIColor.white
                                        }))
                            }
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray5), lineWidth: 1)
                            )
                            .padding(.horizontal, 20)
                        }
                        
                        // Sign Up Button
                        Button(action: signUp) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                
                                Text("Sign Up")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isLoading || !isFormValid)
                        .padding(.horizontal, 20)
                        
                        // Login Link
                        HStack {
                            Text("Already have an account?")
                                .foregroundColor(.secondary)
                            
                            Button("Login") {
                                presentationMode.wrappedValue.dismiss()
                            }
                            .foregroundColor(.blue)
                        }
                        .font(.subheadline)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingPhotoLibrary) {
            ProfileImagePicker(image: $profileImage)
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
        .alert("Sign Up Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var isFormValid: Bool {
        return !firstName.isEmpty && 
               !lastName.isEmpty &&
               !email.isEmpty && 
               !password.isEmpty && 
               !confirmPassword.isEmpty && 
               password == confirmPassword &&
               password.count >= 6
    }
    
    private func signUp() {
        // Validate form
        guard isFormValid else {
            if password != confirmPassword {
                alertMessage = "Passwords do not match."
            } else if password.count < 6 {
                alertMessage = "Password must be at least 6 characters long."
            } else {
                alertMessage = "Please fill in all fields."
            }
            showingAlert = true
            return
        }
        
        isLoading = true
        
        // Use Firebase authentication with new fields
        authManager.signUp(email: email, firstName: firstName, lastName: lastName, password: password, profileImage: profileImage, avatarName: selectedAvatarName) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(_):
                    // User created successfully - Firebase auth state listener will handle the rest
                    presentationMode.wrappedValue.dismiss()
                case .failure(let error):
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - ProfileImagePicker
struct ProfileImagePicker: UIViewControllerRepresentable {
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
        let parent: ProfileImagePicker
        
        init(_ parent: ProfileImagePicker) {
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
    SignUpView()
}
