//
//  FirestoreShoppingList.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 15/09/2025.
//

import Foundation
import FirebaseFirestore

struct FirestoreShoppingList: Codable, Identifiable {
    @DocumentID var id: String?
    let userId: String
    let productId: String
    let isChecked: Bool
    let addedDate: Date
    let lastUpdated: Date
    
    // Convert from local data to FirestoreShoppingList
    init(userId: String, productId: String, isChecked: Bool, addedDate: Date = Date()) {
        self.userId = userId
        self.productId = productId
        self.isChecked = isChecked
        self.addedDate = addedDate
        self.lastUpdated = Date()
    }
    
    // Convert from FirestoreShoppingList to local data
    func toShoppingListItem() -> (productId: UUID, isChecked: Bool) {
        return (UUID(uuidString: productId)!, isChecked)
    }
}

