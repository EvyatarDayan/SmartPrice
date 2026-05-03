//
//  ProductAllergyHelper.swift
//  SmartPrice
//
//  Created by AI Assistant on 10/10/2025.
//

import SwiftUI

extension ProductWithMultipleStores {
    /// Returns true if this product contains any of the user's selected allergies
    var containsUserAllergens: Bool {
        let allergyManager = AllergyManager.shared
        let result = allergyManager.checkProductForAllergies(self)
        return result.hasAnyIssues
    }
    
    /// Returns the allergy check result for this product
    var allergyCheckResult: AllergyCheckResult {
        return AllergyManager.shared.checkProductForAllergies(self)
    }
}

extension Product {
    /// Returns true if this product contains any of the user's selected allergies
    var containsUserAllergens: Bool {
        let allergyManager = AllergyManager.shared
        let result = allergyManager.checkProductForAllergies(self)
        return result.hasAnyIssues
    }
    
    /// Returns the allergy check result for this product
    var allergyCheckResult: AllergyCheckResult {
        return AllergyManager.shared.checkProductForAllergies(self)
    }
}
