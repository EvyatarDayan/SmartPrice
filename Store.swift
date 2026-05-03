//
//  Store.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 10/09/2025.
//

import Foundation

struct Store: Identifiable, Codable {
    let id = UUID()
    let name: String
    let logoName: String
    
    static let knownStores = [
//        Store(name: "Stockholms", logoName: "stockholms_logo"),
        Store(name: "Willys", logoName: "willys_logo"),
        Store(name: "Coop", logoName: "coop_logo"),
        Store(name: "ICA", logoName: "ica_logo"),
        Store(name: "Hemköp", logoName: "hemkop_logo")
    ]
    
    static func getLogoName(for storeName: String) -> String? {
        return knownStores.first { $0.name == storeName }?.logoName
    }
}
