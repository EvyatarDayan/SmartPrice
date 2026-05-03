import Foundation
import FirebaseFirestore

struct FirestoreUser: Identifiable, Codable {
    var id: String? // User ID (same as Firebase Auth UID)
    let email: String?
    let firstName: String?
    let lastName: String?
    let profileImageUrl: String? // URL to profile image in Firebase Storage
    let avatarName: String? // Selected avatar name (e.g., "avatar1", "avatar2")
    let createdAt: Date
    var lastUpdated: Date
    
    // Shopping list data stored as a map of productId -> isChecked
    var shoppingList: [String: Bool] = [:]
    
    // Computed property for full name
    var displayName: String {
        if let firstName = firstName, let lastName = lastName {
            return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        } else if let firstName = firstName {
            return firstName
        } else if let lastName = lastName {
            return lastName
        } else {
            return email?.components(separatedBy: "@").first ?? "User"
        }
    }
    
    // Custom initializer for creating new users
    init(id: String, email: String? = nil, firstName: String? = nil, lastName: String? = nil, profileImageUrl: String? = nil, avatarName: String? = nil) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.profileImageUrl = profileImageUrl
        self.avatarName = avatarName
        self.createdAt = Date()
        self.lastUpdated = Date()
        self.shoppingList = [:]
    }
    
    // Update method to set lastUpdated
    mutating func markUpdated() {
        self.lastUpdated = Date()
    }
    
    // Shopping list management methods
    mutating func addToShoppingList(productId: String, isChecked: Bool = false) {
        shoppingList[productId] = isChecked
        markUpdated()
    }
    
    mutating func removeFromShoppingList(productId: String) {
        shoppingList.removeValue(forKey: productId)
        markUpdated()
    }
    
    mutating func toggleChecked(productId: String) {
        if let currentState = shoppingList[productId] {
            shoppingList[productId] = !currentState
            markUpdated()
        }
    }
    
    func isInShoppingList(productId: String) -> Bool {
        return shoppingList[productId] != nil
    }
    
    func isChecked(productId: String) -> Bool {
        return shoppingList[productId] ?? false
    }
    
    mutating func clearAllChecked() {
        for (productId, _) in shoppingList {
            if shoppingList[productId] == true {
                shoppingList[productId] = false
            }
        }
        markUpdated()
    }
    
    mutating func clearAllShoppingList() {
        shoppingList.removeAll()
        markUpdated()
    }
}
