//
//  AuthenticationView.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 15/09/2025.
//

import SwiftUI

struct AuthenticationView: View {
    @StateObject private var authManager = FirebaseAuthManager.shared
    @State private var showingSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showPassword = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header (matching SignUpView style)
                    VStack(spacing: 16) {
                        Text("Welcome Back")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Login to your account")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, 20)
                    
                    VStack(spacing: 32) {
                        // Account Information Section (matching SignUpView)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("ACCOUNT INFORMATION")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 16)
                            
                            VStack(spacing: 0) {
                                // Email Field
                                TextField("Email", text: $email)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(Color(.systemBackground))
                                
                                Divider()
                                
                                // Password Field
                                HStack {
                                    if showPassword {
                                        TextField("Password", text: $password)
                                            .textFieldStyle(PlainTextFieldStyle())
                                    } else {
                                        SecureField("Password", text: $password)
                                            .textFieldStyle(PlainTextFieldStyle())
                                    }
                                    
                                    Button(action: {
                                        showPassword.toggle()
                                    }) {
                                        Image(systemName: showPassword ? "eye.slash" : "eye")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 16))
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color(.systemBackground))
                            }
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray5), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        
                        // Sign In Button (matching SignUpView button)
                        Button(action: handleSignIn) {
                            HStack {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Login")
//                                        .font(.system(size: 22, weight: .semibold))
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(isFormValid ? Color.blue : Color.gray.opacity(0.4))
                            .cornerRadius(12)
                        }
                        .disabled(authManager.isLoading || !isFormValid)
                        .padding(.horizontal, 20)
                        
                        // Sign Up Link
                        Button(action: {
                            showingSignUp = true
                        }) {
                            Text("Don't have an account? Sign Up")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        
                        // Forgot Password Button
                        Button(action: {
                            // TODO: Implement forgot password
                        }) {
                            Text("Forgot Password?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 60)
                    }
                    .padding(.top, 32)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
            }
            .alert("Authentication", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var isFormValid: Bool {
        return !email.isEmpty && !password.isEmpty
    }
    
    private func handleSignIn() {
        authManager.signIn(email: email, password: password) { result in
            switch result {
            case .success:
                // Success is handled by the auth state listener
                break
            case .failure(_):
                alertMessage = "Incorrect email or password. Try again."
                showingAlert = true
            }
        }
    }
}

#Preview {
    AuthenticationView()
}
