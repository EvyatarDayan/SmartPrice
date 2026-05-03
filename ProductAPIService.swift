//
//  ProductAPIService.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 10/09/2025.
//

import Foundation

// MARK: - Open Food Facts API Models
struct OpenFoodFactsResponse: Codable {
    let status: Int
    let product: OpenFoodFactsProduct?
}

struct OpenFoodFactsProduct: Codable {
    let productName: String?
    let brands: String?
    let categories: String?
    let imageUrl: String?
    let quantity: String?
    let packaging: String?
    let ingredients: String?
    let ingredientsText: String?
    let allergens: String?
    let allergensTags: [String]?
    let traces: String?
    let tracesTags: [String]?
    
    // Nutritional data fields
    let nutriscoreGrade: String?
    let nutriments: Nutriments?
    let nutritionScoreFr: Int?
    let novaGroup: Int?
    
    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case brands
        case categories
        case imageUrl = "image_url"
        case quantity
        case packaging
        case ingredients
        case ingredientsText = "ingredients_text"
        case allergens
        case allergensTags = "allergens_tags"
        case traces
        case tracesTags = "traces_tags"
        // Nutritional data keys
        case nutriscoreGrade = "nutriscore_grade"
        case nutriments
        case nutritionScoreFr = "nutrition-score-fr"
        case novaGroup = "nova-group"
    }
    
    // Custom decoder to handle any parsing issues gracefully
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode each field, but don't fail if any field fails
        productName = try? container.decodeIfPresent(String.self, forKey: .productName)
        brands = try? container.decodeIfPresent(String.self, forKey: .brands)
        categories = try? container.decodeIfPresent(String.self, forKey: .categories)
        imageUrl = try? container.decodeIfPresent(String.self, forKey: .imageUrl)
        quantity = try? container.decodeIfPresent(String.self, forKey: .quantity)
        packaging = try? container.decodeIfPresent(String.self, forKey: .packaging)
        ingredients = try? container.decodeIfPresent(String.self, forKey: .ingredients)
        ingredientsText = try? container.decodeIfPresent(String.self, forKey: .ingredientsText)
        allergens = try? container.decodeIfPresent(String.self, forKey: .allergens)
        allergensTags = try? container.decodeIfPresent([String].self, forKey: .allergensTags)
        traces = try? container.decodeIfPresent(String.self, forKey: .traces)
        tracesTags = try? container.decodeIfPresent([String].self, forKey: .tracesTags)
        nutriscoreGrade = try? container.decodeIfPresent(String.self, forKey: .nutriscoreGrade)
        nutriments = try? container.decodeIfPresent(Nutriments.self, forKey: .nutriments)
        nutritionScoreFr = try? container.decodeIfPresent(Int.self, forKey: .nutritionScoreFr)
        novaGroup = try? container.decodeIfPresent(Int.self, forKey: .novaGroup)
    }
}

struct Nutriments: Codable {
    let energyKcal100g: Double?
    let fat100g: Double?
    let saturatedFat100g: Double?
    let sugars100g: Double?
    let salt100g: Double?
    let proteins100g: Double?
    let carbohydrates100g: Double?
    let fiber100g: Double?
    let sodium100g: Double?
    
    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case fat100g = "fat_100g"
        case saturatedFat100g = "saturated-fat_100g"
        case sugars100g = "sugars_100g"
        case salt100g = "salt_100g"
        case proteins100g = "proteins_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case fiber100g = "fiber_100g"
        case sodium100g = "sodium_100g"
    }
    
    // Custom decoder to handle any parsing issues gracefully
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode each field, but don't fail if any field fails
        energyKcal100g = try? container.decodeIfPresent(Double.self, forKey: .energyKcal100g)
        fat100g = try? container.decodeIfPresent(Double.self, forKey: .fat100g)
        saturatedFat100g = try? container.decodeIfPresent(Double.self, forKey: .saturatedFat100g)
        sugars100g = try? container.decodeIfPresent(Double.self, forKey: .sugars100g)
        salt100g = try? container.decodeIfPresent(Double.self, forKey: .salt100g)
        proteins100g = try? container.decodeIfPresent(Double.self, forKey: .proteins100g)
        carbohydrates100g = try? container.decodeIfPresent(Double.self, forKey: .carbohydrates100g)
        fiber100g = try? container.decodeIfPresent(Double.self, forKey: .fiber100g)
        sodium100g = try? container.decodeIfPresent(Double.self, forKey: .sodium100g)
    }
}

// MARK: - Product API Service
class ProductAPIService: ObservableObject {
    static let shared = ProductAPIService()
    
    private let baseURL = "https://world.openfoodfacts.org/api/v0/product"
    private let session = URLSession.shared
    private let imageDownloadService = ImageDownloadService.shared
    
    private init() {}
    
    func fetchProductInfo(barcode: String) async throws -> OpenFoodFactsProduct? {
        guard let url = URL(string: "\(baseURL)/\(barcode).json") else {
            throw APIError.invalidURL
        }
        
        print("DEBUG: 🔍 Fetching product info for barcode: \(barcode)")
        print("DEBUG: 🔍 URL: \(url)")
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("DEBUG: ❌ Invalid response type")
            throw APIError.invalidResponse
        }
        
        print("DEBUG: 🔍 HTTP Status Code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            print("DEBUG: ❌ HTTP Error: \(httpResponse.statusCode)")
            throw APIError.invalidResponse
        }
        
        print("DEBUG: 🔍 Response data size: \(data.count) bytes")
        
        // Try to decode the response
        do {
            let openFoodFactsResponse = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)
            print("DEBUG: 🔍 Decoded response status: \(openFoodFactsResponse.status)")
            
            guard openFoodFactsResponse.status == 1 else {
                print("DEBUG: ❌ Product not found (status: \(openFoodFactsResponse.status))")
                throw APIError.productNotFound
            }
            
            print("DEBUG: ✅ Product found successfully")
            return openFoodFactsResponse.product
        } catch {
            print("DEBUG: ❌ JSON Decoding Error: \(error)")
            print("DEBUG: ❌ Error details: \(error.localizedDescription)")
            
            // Try to print the raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("DEBUG: 🔍 Raw response (first 500 chars): \(String(responseString.prefix(500)))")
            }
            
            throw APIError.invalidResponse
        }
    }
    
    func searchProduct(barcode: String) async -> ProductSearchResult {
        do {
            let productInfo = try await fetchProductInfo(barcode: barcode)
            
            if let product = productInfo {
                return .found(ProductData(
                    name: product.productName ?? "Unknown",
                    brand: product.brands,
                    category: extractCategory(from: product.categories),
                    imageUrl: product.imageUrl,
                    quantity: product.quantity,
                    packaging: product.packaging,
                    ingredients: product.ingredientsText ?? product.ingredients,
                    allergens: product.allergens,
                    allergensTags: product.allergensTags,
                    traces: product.traces,
                    tracesTags: product.tracesTags,
                    nutriscoreGrade: product.nutriscoreGrade,
                    nutritionalInfo: extractNutritionalInfo(from: product)
                ))
            } else {
                return .notFound
            }
        } catch {
            return .error(error.localizedDescription)
        }
    }
    
    func searchProductWithImage(barcode: String) async -> ProductSearchResultWithImage {
        do {
            let productInfo = try await fetchProductInfo(barcode: barcode)
            
            if let product = productInfo {
                var imageData: Data? = nil
                
                // Download image if URL is available
                if let imageUrl = product.imageUrl {
                    imageData = await imageDownloadService.downloadImageData(from: imageUrl)
                }
                
                return .found(ProductDataWithImage(
                    name: product.productName ?? "Unknown",
                    brand: product.brands,
                    category: extractCategory(from: product.categories),
                    imageUrl: product.imageUrl,
                    imageData: imageData,
                    quantity: product.quantity,
                    packaging: product.packaging,
                    ingredients: product.ingredientsText ?? product.ingredients,
                    allergens: product.allergens,
                    allergensTags: product.allergensTags,
                    traces: product.traces,
                    tracesTags: product.tracesTags,
                    nutriscoreGrade: product.nutriscoreGrade,
                    nutritionalInfo: extractNutritionalInfo(from: product)
                ))
            } else {
                return .notFound
            }
        } catch {
            return .error(error.localizedDescription)
        }
    }
    
    private func extractNutritionalInfo(from product: OpenFoodFactsProduct) -> NutritionalInfo? {
        guard let nutriments = product.nutriments else { return nil }
        
        return NutritionalInfo(
            energyKcal: nutriments.energyKcal100g,
            fat: nutriments.fat100g,
            saturatedFat: nutriments.saturatedFat100g,
            sugars: nutriments.sugars100g,
            salt: nutriments.salt100g,
            proteins: nutriments.proteins100g,
            carbohydrates: nutriments.carbohydrates100g,
            fiber: nutriments.fiber100g,
            nutritionScore: product.nutritionScoreFr,
            novaGroup: product.novaGroup
        )
    }
    
    private func extractCategory(from categories: String?) -> String {
        guard let categories = categories else { 
            print("DEBUG: No categories provided, returning 'Other'")
            return "Other" 
        }
        
        print("DEBUG: Raw categories from API: '\(categories)'")
        
        // Extract the first category from the comma-separated list
        let firstCategory = categories.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? "Other"
        
        print("DEBUG: First category extracted: '\(firstCategory)'")
        
        // Map to our app's categories - more comprehensive mapping
        let categoryMapping: [String: String] = [
            // Fruits and Vegetables
            "en:fruits": "Produce",
            "en:vegetables": "Produce",
            "fruits": "Produce",
            "vegetables": "Produce",
            "produce": "Produce",
            
            // Dairy
            "en:dairy": "Dairy",
            "dairy": "Dairy",
            "milk": "Dairy",
            "cheese": "Dairy",
            "yogurt": "Dairy",
            "butter": "Dairy",
            
            // Meat
            "en:meats": "Meat",
            "meat": "Meat",
            "beef": "Meat",
            "pork": "Meat",
            "chicken": "Meat",
            "fish": "Meat",
            "seafood": "Meat",
            
            // Bakery
            "en:breads": "Bakery",
            "bread": "Bakery",
            "bakery": "Bakery",
            "pastry": "Bakery",
            "cake": "Bakery",
            "cookies": "Bakery",
            
            // Beverages
            "en:beverages": "Beverages",
            "beverages": "Beverages",
            "drinks": "Beverages",
            "juice": "Beverages",
            "soda": "Beverages",
            "water": "Beverages",
            "coffee": "Beverages",
            "tea": "Beverages",
            
            // Snacks
            "en:snacks": "Snacks",
            "snacks": "Snacks",
            "chips": "Snacks",
            "candy": "Snacks",
            "chocolate": "Snacks",
            "nuts": "Snacks",
            
            // Household
            "en:household": "Household",
            "household": "Household",
            "cleaning": "Household",
            "detergent": "Household",
            "soap": "Household",
            "toilet": "Household",
            
            // Electronics
            "en:electronics": "Electronics",
            "electronics": "Electronics",
            "computer": "Electronics",
            "phone": "Electronics",
            "camera": "Electronics"
        ]
        
        // Try exact match first
        for (key, value) in categoryMapping {
            if firstCategory.lowercased() == key.lowercased() {
                print("DEBUG: Found exact category match: '\(key)' -> '\(value)'")
                return value
            }
        }
        
        // Try partial match
        for (key, value) in categoryMapping {
            if firstCategory.lowercased().contains(key.lowercased()) {
                print("DEBUG: Found partial category match: '\(key)' -> '\(value)'")
                return value
            }
        }
        
        // Try reverse match (key contains firstCategory)
        for (key, value) in categoryMapping {
            if key.lowercased().contains(firstCategory.lowercased()) {
                print("DEBUG: Found reverse category match: '\(key)' -> '\(value)'")
                return value
            }
        }
        
        print("DEBUG: No category match found, returning 'Other'")
        return "Other"
    }
    
    // MARK: - Allergen Management
    
    /// Fetches a sample of products to extract all available allergens from the API
    func getAllAvailableAllergens() async -> [String] {
        // Common barcodes to sample for allergen data
        let sampleBarcodes = [
            "3017620422003", // Nutella
            "7622210449283", // Oreo
            "8712561715039", // Dutch product
            "8712561715046", // Another Dutch product
            "8712561715053"  // Another Dutch product
        ]
        
        var allAllergens: Set<String> = []
        
        for barcode in sampleBarcodes {
            do {
                if let product = try await fetchProductInfo(barcode: barcode) {
                    // Add allergens from tags
                    if let allergensTags = product.allergensTags {
                        for allergen in allergensTags {
                            // Remove the "en:" prefix and add to set
                            let cleanAllergen = allergen.replacingOccurrences(of: "en:", with: "")
                            allAllergens.insert(cleanAllergen)
                        }
                    }
                    
                    // Add traces from tags
                    if let tracesTags = product.tracesTags {
                        for trace in tracesTags {
                            let cleanTrace = trace.replacingOccurrences(of: "en:", with: "")
                            allAllergens.insert(cleanTrace)
                        }
                    }
                }
            } catch {
                print("DEBUG: Failed to fetch product \(barcode): \(error)")
            }
        }
        
        return Array(allAllergens).sorted()
    }
    
    /// Gets a comprehensive list of common allergens based on Open Food Facts taxonomy
    func getCommonAllergens() -> [String] {
        return [
            "milk",
            "eggs", 
            "fish",
            "crustaceans",
            "tree-nuts",
            "peanuts",
            "wheat",
            "soybeans",
            "sesame",
            "mustard",
            "celery",
            "lupin",
            "molluscs",
            "sulphites",
            "gluten",
            "nuts",
            "almonds",
            "walnuts",
            "hazelnuts",
            "pistachios",
            "cashews",
            "pecans",
            "brazil-nuts",
            "macadamia-nuts",
            "pine-nuts"
        ]
    }
}

// MARK: - Product Data Models
struct ProductData {
    let name: String
    let brand: String?
    let category: String
    let imageUrl: String?
    let quantity: String?
    let packaging: String?
    let ingredients: String?
    let allergens: String?
    let allergensTags: [String]?
    let traces: String?
    let tracesTags: [String]?
    let nutriscoreGrade: String?
    let nutritionalInfo: NutritionalInfo?
}

struct ProductDataWithImage {
    let name: String
    let brand: String?
    let category: String
    let imageUrl: String?
    let imageData: Data?
    let quantity: String?
    let packaging: String?
    let ingredients: String?
    let allergens: String?
    let allergensTags: [String]?
    let traces: String?
    let tracesTags: [String]?
    let nutriscoreGrade: String?
    let nutritionalInfo: NutritionalInfo?
}

enum ProductSearchResult {
    case found(ProductData)
    case notFound
    case error(String)
}

enum ProductSearchResultWithImage {
    case found(ProductDataWithImage)
    case notFound
    case error(String)
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case productNotFound
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .productNotFound:
            return "Product not found in database"
        case .networkError:
            return "Network error occurred"
        }
    }
}
