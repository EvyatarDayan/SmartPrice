//
//  FirstLaunchManager.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 15/09/2025.
//

import Foundation
import SwiftUI

class FirstLaunchManager: ObservableObject {
    static let shared = FirstLaunchManager()
    
    @Published var isFirstLaunch: Bool {
        didSet {
            UserDefaults.standard.set(!isFirstLaunch, forKey: "hasLaunchedBefore")
        }
    }
    
    @Published var hasRequestedLocationPermission: Bool {
        didSet {
            UserDefaults.standard.set(hasRequestedLocationPermission, forKey: "hasRequestedLocationPermission")
        }
    }
    
    private init() {
        self.isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        self.hasRequestedLocationPermission = UserDefaults.standard.bool(forKey: "hasRequestedLocationPermission")
    }
    
    func markAsLaunched() {
        isFirstLaunch = false
    }
    
    func markLocationPermissionRequested() {
        hasRequestedLocationPermission = true
    }
    
    func shouldRequestLocationPermission() -> Bool {
        return isFirstLaunch && !hasRequestedLocationPermission
    }
}

