//
//  ProductDatabase.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 10/09/2025.
//

import Foundation

struct ProductInfo: Codable {
    let name: String
    let brand: String?
    let category: String
}

class ProductDatabase: ObservableObject {
    static let shared = ProductDatabase()
    
    // Mock database - in a real app, this would be a proper database or API
    private let productDatabase: [String: ProductInfo] = [
        "1234567890123": ProductInfo(name: "Organic Bananas", brand: "Whole Foods", category: "Produce"),
        "2345678901234": ProductInfo(name: "Whole Milk", brand: "Horizon", category: "Dairy"),
        "3456789012345": ProductInfo(name: "Bread Loaf", brand: "Trader Joe's", category: "Bakery"),
        "4567890123456": ProductInfo(name: "Chicken Breast", brand: "Kirkland", category: "Meat"),
        "5678901234567": ProductInfo(name: "Apples", brand: "Whole Foods", category: "Produce"),
        "6789012345678": ProductInfo(name: "Greek Yogurt", brand: "Chobani", category: "Dairy"),
        "7890123456789": ProductInfo(name: "Eggs (12 pack)", brand: "Trader Joe's", category: "Dairy"),
        "8901234567890": ProductInfo(name: "Ground Beef", brand: "Kirkland", category: "Meat"),
        "1111111111111": ProductInfo(name: "Coca Cola", brand: "Coca-Cola", category: "Beverages"),
        "2222222222222": ProductInfo(name: "iPhone 15", brand: "Apple", category: "Electronics"),
        "3333333333333": ProductInfo(name: "Tide Detergent", brand: "Tide", category: "Household"),
        "4444444444444": ProductInfo(name: "Oreo Cookies", brand: "Nabisco", category: "Snacks")
    ]
    
    private init() {}
    
    func lookupProduct(barcode: String) -> ProductInfo? {
        return productDatabase[barcode]
    }
    
    func isProductInDatabase(barcode: String) -> Bool {
        return productDatabase[barcode] != nil
    }
}

