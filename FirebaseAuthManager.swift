//
//  FirebaseAuthManager.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 15/09/2025.
//

import Foundation
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
import SwiftUI

// Type alias to avoid conflicts with custom User type
typealias FirebaseUser = FirebaseAuth.User

class FirebaseAuthManager: ObservableObject {
    static let shared = FirebaseAuthManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: FirebaseUser?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {
        // Configure Firebase if not already configured
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        // Clear any local user data to ensure we only use Firebase authentication
        UserManager.shared.clearAllLocalUserData()
        
        // Listen for authentication state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isAuthenticated = user != nil
                
                // Notify shopping list manager of auth state change
                print("DEBUG: FirebaseAuthManager - Auth state changed, notifying shopping list manager")
                FirestoreShoppingListManager.shared.handleAuthStateChange(user: user)
            }
        }
        
        // If user is already authenticated, notify shopping list manager immediately
        if let currentUser = Auth.auth().currentUser {
            DispatchQueue.main.async {
                print("DEBUG: FirebaseAuthManager - User already authenticated on startup, notifying shopping list manager")
                self.currentUser = currentUser
                self.isAuthenticated = true
                FirestoreShoppingListManager.shared.handleAuthStateChange(user: currentUser)
            }
        }
    }
    
    // MARK: - Authentication Methods
    
    func signUp(email: String, password: String, completion: @escaping (Result<FirebaseUser, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                } else if let user = result?.user {
                    self?.currentUser = user
                    self?.isAuthenticated = true
                    completion(.success(user))
                }
            }
        }
    }
    
    func signUp(email: String, firstName: String, lastName: String, password: String, profileImage: UIImage? = nil, avatarName: String? = nil, completion: @escaping (Result<FirebaseUser, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                } else if let user = result?.user {
                    // Update the user's display name
                    let displayName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
                    let changeRequest = user.createProfileChangeRequest()
                    changeRequest.displayName = displayName
                    
                    changeRequest.commitChanges { [weak self] error in
                        if let error = error {
                            print("DEBUG: Error updating user profile: \(error.localizedDescription)")
                        } else {
                            print("DEBUG: User profile updated successfully")
                        }
                    }
                    
                    // Create Firestore user document with new structure
                    self?.createFirestoreUserDocument(user: user, firstName: firstName, lastName: lastName, profileImage: profileImage, avatarName: avatarName)
                    
                    self?.currentUser = user
                    self?.isAuthenticated = true
                    completion(.success(user))
                }
            }
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Result<FirebaseUser, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                } else if let user = result?.user {
                    self?.currentUser = user
                    self?.isAuthenticated = true
                    completion(.success(user))
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            isAuthenticated = false
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func resetPassword(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    // MARK: - User Profile Updates
    
    func updateUserAvatar(avatarName: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseAuthManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user is currently signed in"])))
            return
        }
        
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "avatarName": avatarName ?? "",
            "lastUpdated": Timestamp(date: Date())
        ]
        
        db.collection("users").document(userId).updateData(userData) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("DEBUG: Error updating user avatar: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    print("DEBUG: User avatar updated successfully")
                    completion(.success(()))
                }
            }
        }
    }
    
    func updateUserProfile(firstName: String, lastName: String, avatarName: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseAuthManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user is currently signed in"])))
            return
        }
        
        let displayName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        
        // Update Firebase Auth profile
        updateUserProfile(displayName: displayName, photoURL: nil) { [weak self] result in
            switch result {
            case .success():
                // Update Firestore user document
                let db = Firestore.firestore()
                let userData: [String: Any] = [
                    "firstName": firstName,
                    "lastName": lastName,
                    "avatarName": avatarName ?? "",
                    "lastUpdated": Timestamp(date: Date())
                ]
                
                db.collection("users").document(userId).updateData(userData) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("DEBUG: Error updating user profile in Firestore: \(error.localizedDescription)")
                            completion(.failure(error))
                        } else {
                            print("DEBUG: User profile updated successfully in Firestore")
                            completion(.success(()))
                        }
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - User Management & Deletion
    
    // Method to check if email exists in Firebase Authentication
    func checkIfEmailExists(email: String, completion: @escaping (Bool) -> Void) {
        // Note: Firebase doesn't provide a direct way to check if an email exists
        // The only way is to attempt sign-in or use Firebase Admin SDK
        // For now, we'll rely on the sign-up error message
        completion(false) // This is a placeholder - Firebase will return error on sign-up if email exists
    }
    
    func deleteCurrentUser(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = currentUser else {
            completion(.failure(NSError(domain: "FirebaseAuthManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user is currently signed in"])))
            return
        }
        
        let userId = user.uid
        let db = Firestore.firestore()
        
        // First, delete the Firestore user document
        db.collection("users").document(userId).delete { [weak self] firestoreError in
            if let firestoreError = firestoreError {
                print("DEBUG: Error deleting Firestore user document: \(firestoreError.localizedDescription)")
                completion(.failure(firestoreError))
                return
            }
            
            print("DEBUG: Firestore user document deleted successfully")
            
            // Then delete the user from Firebase Authentication
            user.delete { [weak self] authError in
                DispatchQueue.main.async {
                    if let authError = authError {
                        print("DEBUG: Error deleting Firebase Auth user: \(authError.localizedDescription)")
                        completion(.failure(authError))
                    } else {
                        print("DEBUG: Firebase Auth user deleted successfully")
                        self?.currentUser = nil
                        self?.isAuthenticated = false
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    // MARK: - User Profile Methods
    
    func updateUserProfile(displayName: String?, photoURL: URL?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "FirebaseAuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])))
            return
        }
        
        let changeRequest = user.createProfileChangeRequest()
        if let displayName = displayName {
            changeRequest.displayName = displayName
        }
        if let photoURL = photoURL {
            changeRequest.photoURL = photoURL
        }
        
        changeRequest.commitChanges { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    func clearError() {
        errorMessage = nil
    }
    
    var userEmail: String? {
        return currentUser?.email
    }
    
    var userDisplayName: String? {
        return currentUser?.displayName
    }
    
    var userUID: String? {
        return currentUser?.uid
    }
    
    // MARK: - Firestore User Document Management
    
    private func createFirestoreUserDocument(user: FirebaseUser, firstName: String, lastName: String, profileImage: UIImage?, avatarName: String? = nil) {
        let db = Firestore.firestore()
        
        // If there's a profile image, upload it first
        if let profileImage = profileImage, let imageData = profileImage.jpegData(compressionQuality: 0.8) {
            FirebaseStorageManager.shared.uploadProfileImage(imageData, userId: user.uid) { [weak self] result in
                switch result {
                case .success(let imageUrl):
                    self?.saveUserDocument(user: user, firstName: firstName, lastName: lastName, profileImageUrl: imageUrl, avatarName: avatarName, db: db)
                case .failure(let error):
                    print("DEBUG: Error uploading profile image: \(error.localizedDescription)")
                    // Still save user document without image
                    self?.saveUserDocument(user: user, firstName: firstName, lastName: lastName, profileImageUrl: nil, avatarName: avatarName, db: db)
                }
            }
        } else {
            // No profile image, save user document directly
            saveUserDocument(user: user, firstName: firstName, lastName: lastName, profileImageUrl: nil, avatarName: avatarName, db: db)
        }
    }
    
    
    private func saveUserDocument(user: FirebaseUser, firstName: String, lastName: String, profileImageUrl: String?, avatarName: String? = nil, db: Firestore) {
        let userData: [String: Any] = [
            "id": user.uid,
            "email": user.email ?? "",
            "firstName": firstName,
            "lastName": lastName,
            "profileImageUrl": profileImageUrl ?? "",
            "avatarName": avatarName ?? "",
            "createdAt": Timestamp(date: Date()),
            "lastUpdated": Timestamp(date: Date()),
            "shoppingList": [:]
        ]
        
        db.collection("users").document(user.uid).setData(userData) { error in
            if let error = error {
                print("DEBUG: Error creating Firestore user document: \(error.localizedDescription)")
            } else {
                print("DEBUG: Firestore user document created successfully with new structure")
            }
        }
    }
}
