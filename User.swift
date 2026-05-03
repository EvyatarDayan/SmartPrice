//
//  User.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 10/09/2025.
//

import Foundation

struct User: Codable, Identifiable {
    let id = UUID()
    let email: String
    let firstName: String
    let lastName: String
    var password: String // In a real app, this would be hashed
    let profileImageData: Data? // Store profile image data locally
    let createdAt: Date
    
    // Computed property for full name
    var name: String {
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
    
    init(email: String, firstName: String, lastName: String, password: String, profileImageData: Data? = nil) {
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.password = password
        self.profileImageData = profileImageData
        self.createdAt = Date()
    }
}

// User authentication manager
class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @Published var currentUser: User?
    @Published var isSignedIn: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let currentUserKey = "currentUser"
    private let usersKey = "registeredUsers"
    
    private init() {
        loadCurrentUser()
    }
    
    // MARK: - Authentication Methods
    
    func signIn(email: String, password: String) -> Bool {
        let users = getRegisteredUsers()
        
        if let user = users.first(where: { $0.email.lowercased() == email.lowercased() && $0.password == password }) {
            currentUser = user
            isSignedIn = true
            saveCurrentUser()
            return true
        }
        
        return false
    }
    
    func signUp(email: String, name: String, password: String) -> Bool {
        // Parse the name into firstName and lastName
        let nameComponents = name.components(separatedBy: " ")
        let firstName = nameComponents.first ?? ""
        let lastName = nameComponents.count > 1 ? nameComponents.dropFirst().joined(separator: " ") : ""
        
        return signUp(email: email, firstName: firstName, lastName: lastName, password: password, profileImageData: nil)
    }
    
    func signUp(email: String, firstName: String, lastName: String, password: String, profileImageData: Data? = nil) -> Bool {
        let users = getRegisteredUsers()
        
        // Check if user already exists
        if users.contains(where: { $0.email.lowercased() == email.lowercased() }) {
            return false
        }
        
        // Create new user
        let newUser = User(email: email, firstName: firstName, lastName: lastName, password: password, profileImageData: profileImageData)
        var updatedUsers = users
        updatedUsers.append(newUser)
        
        // Save updated users list
        if let encoded = try? JSONEncoder().encode(updatedUsers) {
            userDefaults.set(encoded, forKey: usersKey)
        }
        
        // Sign in the new user
        currentUser = newUser
        isSignedIn = true
        saveCurrentUser()
        
        return true
    }
    
    func signOut() {
        currentUser = nil
        isSignedIn = false
        userDefaults.removeObject(forKey: currentUserKey)
    }
    
    // Clear all local user data - use when switching to Firebase-only authentication
    func clearAllLocalUserData() {
        userDefaults.removeObject(forKey: currentUserKey)
        userDefaults.removeObject(forKey: usersKey)
        currentUser = nil
        isSignedIn = false
        print("DEBUG: All local user data cleared")
    }
    
    func updateUser(_ updatedUser: User) {
        var users = getRegisteredUsers()
        
        // Find and update the user in the registered users list
        if let index = users.firstIndex(where: { $0.email == currentUser?.email }) {
            users[index] = updatedUser
        }
        
        // Save updated users list
        if let encoded = try? JSONEncoder().encode(users) {
            userDefaults.set(encoded, forKey: usersKey)
        }
        
        // Update current user
        currentUser = updatedUser
        saveCurrentUser()
    }
    
    // MARK: - Data Persistence
    
    private func saveCurrentUser() {
        if let user = currentUser, let encoded = try? JSONEncoder().encode(user) {
            userDefaults.set(encoded, forKey: currentUserKey)
        }
    }
    
    private func loadCurrentUser() {
        if let data = userDefaults.data(forKey: currentUserKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            currentUser = user
            isSignedIn = true
        }
    }
    
    private func getRegisteredUsers() -> [User] {
        if let data = userDefaults.data(forKey: usersKey),
           let users = try? JSONDecoder().decode([User].self, from: data) {
            return users
        }
        return []
    }
}
