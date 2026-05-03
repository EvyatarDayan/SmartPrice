//
//  EditProductView.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 10/09/2025.
//

import SwiftUI
import CryptoKit

struct EditProductView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var apiService = ProductAPIService.shared
    @StateObject private var multiStoreManager = MultiStoreProductManager.shared
    @AppStorage("defaultCurrency") private var defaultCurrency: String = "EUR"
    
    private func getCurrencySymbol(for currency: String) -> String {
        switch currency {
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        case "CAD": return "C$"
        case "AUD": return "A$"
        case "CHF": return "CHF"
        case "CNY": return "¥"
        case "SEK": return "kr"
        case "NZD": return "NZ$"
        case "MXN": return "$"
        case "SGD": return "S$"
        case "HKD": return "HK$"
        case "NOK": return "kr"
        case "DKK": return "kr"
        case "PLN": return "zł"
        case "CZK": return "Kč"
        case "HUF": return "Ft"
        case "ILS": return "₪"
        case "TRY": return "₺"
        case "BRL": return "R$"
        case "INR": return "₹"
        case "KRW": return "₩"
        case "THB": return "฿"
        case "MYR": return "RM"
        case "PHP": return "₱"
        case "IDR": return "Rp"
        case "VND": return "₫"
        case "ZAR": return "R"
        case "EGP": return "£"
        case "AED": return "د.إ"
        case "SAR": return "﷼"
        case "QAR": return "﷼"
        case "KWD": return "د.ك"
        case "BHD": return "د.ب"
        case "OMR": return "﷼"
        case "JOD": return "د.ا"
        case "LBP": return "ل.ل"
        case "ISK": return "kr"
        case "RON": return "lei"
        case "BGN": return "лв"
        case "HRK": return "kn"
        case "RSD": return "дин"
        case "UAH": return "₴"
        case "RUB": return "₽"
        case "BYN": return "Br"
        case "KZT": return "₸"
        case "UZS": return "лв"
        case "KGS": return "лв"
        case "TJS": return "SM"
        case "TMT": return "T"
        case "AZN": return "₼"
        case "GEL": return "₾"
        case "AMD": return "֏"
        case "AFN": return "؋"
        case "PKR": return "₨"
        case "LKR": return "₨"
        case "BDT": return "৳"
        case "NPR": return "₨"
        case "BTN": return "Nu"
        case "MVR": return ".ރ"
        case "MMK": return "K"
        case "LAK": return "₭"
        case "KHR": return "៛"
        case "BND": return "B$"
        case "FJD": return "FJ$"
        case "PGK": return "K"
        case "SBD": return "SI$"
        case "VUV": return "Vt"
        case "WST": return "WS$"
        case "TOP": return "T$"
        case "XPF": return "₣"
        case "NIO": return "C$"
        case "GTQ": return "Q"
        case "HNL": return "L"
        case "SVC": return "₡"
        case "BZD": return "BZ$"
        case "JMD": return "J$"
        case "TTD": return "TT$"
        case "BBD": return "Bds$"
        case "XCD": return "$"
        case "AWG": return "ƒ"
        case "BMD": return "$"
        case "KYD": return "$"
        case "BSD": return "$"
        case "DOP": return "RD$"
        case "HTG": return "G"
        case "CUP": return "$"
        case "PAB": return "B/."
        case "CRC": return "₡"
        case "PYG": return "₲"
        case "UYU": return "$U"
        case "ARS": return "$"
        case "CLP": return "$"
        case "BOB": return "Bs"
        case "PEN": return "S/"
        case "COP": return "$"
        case "VES": return "Bs.S"
        case "GYD": return "G$"
        case "SRD": return "$"
        default: return "$"
        }
    }
    
    @State private var productName = ""
    @State private var brand = ""
    @State private var category = ""
    @State private var barcode = ""
    @State private var showingScanner = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoadingProduct = false
    @State private var productFound = false
    @State private var showingImagePicker = false
    @State private var showingImageOptions = false
    @State private var showingIconPicker = false
    @State private var selectedImage: UIImage?
    @State private var selectedIconName: String?
    @State private var showingDeleteAlert = false
    @State private var showingImageMenu = false
    
    let product: Product
    let onProductUpdated: (Product) -> Void
    let onProductDeleted: ((Product) -> Void)?
    
    private let categories = ["Produce", "Dairy", "Meat", "Bakery", "Beverages", "Snacks", "Household", "Electronics", "Other"]
    
    // Get the multi-store product for this product
    private var multiStoreProduct: ProductWithMultipleStores? {
        // Generate base product ID (without store)
        let baseId = generateBaseProductId(name: product.name, brand: product.brand, category: product.category, barcode: product.barcode)
        return multiStoreManager.getProduct(by: baseId)
    }
    
    private func generateBaseProductId(name: String, brand: String?, category: String, barcode: String?) -> String {
        let contentString = "\(name.lowercased())|\(brand?.lowercased() ?? "")|\(category.lowercased())|\(barcode ?? "")"
        return SHA256.hash(data: contentString.data(using: .utf8)!).compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
    
    private func cleanAllergenText(_ text: String?) -> String? {
        guard let text = text, !text.isEmpty else { return nil }
        
        // Split by comma and clean each allergen
        let allergens = text.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .map { allergen in
                // Remove language prefixes (en:, fr:, de:, es:, etc.)
                let cleaned = allergen.replacingOccurrences(of: "^[a-z]{2}:", with: "", options: .regularExpression)
                // Translate to English
                let translated = translateAllergenToEnglish(cleaned)
                // Capitalize first letter
                return translated.capitalized
            }
            .filter { !$0.isEmpty }
        
        return allergens.isEmpty ? nil : allergens.joined(separator: ", ")
    }
    
    private func cleanIngredientsText(_ text: String?) -> String? {
        guard let text = text, !text.isEmpty else { return nil }
        
        // Split by comma and clean each ingredient
        let ingredients = text.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .map { ingredient in
                // Remove language prefixes (en:, fr:, de:, es:, etc.)
                let cleaned = ingredient.replacingOccurrences(of: "^[a-z]{2}:", with: "", options: .regularExpression)
                // Translate to English
                let translated = translateIngredientToEnglish(cleaned)
                // Capitalize first letter
                return translated.capitalized
            }
            .filter { !$0.isEmpty }
        
        return ingredients.isEmpty ? nil : ingredients.joined(separator: ", ")
    }
    
    private func translateAllergenToEnglish(_ allergen: String) -> String {
        let allergenLower = allergen.lowercased()
        
        // Comprehensive allergen translation dictionary (no duplicates)
        let allergenTranslations: [String: String] = [
            // French
            "lait": "milk",
            "œufs": "eggs",
            "œuf": "eggs",
            "poisson": "fish",
            "crustacés": "crustaceans",
            "crustace": "crustaceans",
            "fruits à coque": "tree nuts",
            "fruits a coque": "tree nuts",
            "noix": "nuts",
            "noisettes": "hazelnuts",
            "amandes": "almonds",
            "noix de cajou": "cashews",
            "noix de pécan": "pecans",
            "noix du brésil": "brazil nuts",
            "noix de macadamia": "macadamia nuts",
            "pignons de pin": "pine nuts",
            "arachides": "peanuts",
            "cacahuètes": "peanuts",
            "soja": "soybeans",
            "sésame": "sesame",
            "moutarde": "mustard",
            "céleri": "celery",
            "lupin": "lupin",
            "mollusques": "molluscs",
            "sulfites": "sulphites",
            "anhydride sulfureux": "sulphites",
            
            // German
            "milch": "milk",
            "eier": "eggs",
            "ei": "eggs",
            "fisch": "fish",
            "krebstiere": "crustaceans",
            "schalenfrüchte": "tree nuts",
            "nüsse": "nuts",
            "haselnüsse": "hazelnuts",
            "mandeln": "almonds",
            "cashewnüsse": "cashews",
            "pecannüsse": "pecans",
            "paranüsse": "brazil nuts",
            "macadamianüsse": "macadamia nuts",
            "pinienkerne": "pine nuts",
            "erdnüsse": "peanuts",
            "sesam": "sesame",
            "senf": "mustard",
            "sellerie": "celery",
            "lupinen": "lupin",
            "weichtiere": "molluscs",
            "schwefeldioxid": "sulphites",
            
            // Spanish
            "leche": "milk",
            "huevos": "eggs",
            "huevo": "eggs",
            "pescado": "fish",
            "crustáceos": "crustaceans",
            "frutos de cáscara": "tree nuts",
            "frutos secos": "nuts",
            "avellanas": "hazelnuts",
            "almendras": "almonds",
            "anacardos": "cashews",
            "nueces de pecán": "pecans",
            "nueces de brasil": "brazil nuts",
            "nueces de macadamia": "macadamia nuts",
            "piñones": "pine nuts",
            "cacahuetes": "peanuts",
            "sésamo": "sesame",
            "mostaza": "mustard",
            "apio": "celery",
            "altramuces": "lupin",
            "moluscos": "molluscs",
            "sulfitos": "sulphites",
            
            // Italian
            "glutine": "gluten",
            "latte": "milk",
            "uova": "eggs",
            "uovo": "eggs",
            "pesce": "fish",
            "crostacei": "crustaceans",
            "frutta a guscio": "tree nuts",
            "noci": "nuts",
            "nocciole": "hazelnuts",
            "mandorle": "almonds",
            "anacardi": "cashews",
            "noci pecan": "pecans",
            "noci del brasile": "brazil nuts",
            "noci di macadamia": "macadamia nuts",
            "pinoli": "pine nuts",
            "arachidi": "peanuts",
            "soia": "soybeans",
            "sesamo": "sesame",
            "senape": "mustard",
            "sedano": "celery",
            "lupini": "lupin",
            "molluschi": "molluscs",
            "solfiti": "sulphites",
            
            // Dutch
            "melk": "milk",
            "eieren": "eggs",
            "vis": "fish",
            "schaaldieren": "crustaceans",
            "noten": "nuts",
            "hazelnoten": "hazelnuts",
            "amandelen": "almonds",
            "cashewnoten": "cashews",
            "pecannoten": "pecans",
            "paranoten": "brazil nuts",
            "macadamianoten": "macadamia nuts",
            "pijnboompitten": "pine nuts",
            "pinda's": "peanuts",
            "mosterd": "mustard",
            "selderij": "celery",
            "lupine": "lupin",
            "weekdieren": "molluscs",
            "sulfieten": "sulphites",
            
            // Norwegian/Swedish/Danish
            "mjölk": "milk",
            "mælk": "milk",
            "egg": "eggs",
            "ägg": "eggs",
            "fisk": "fish",
            "skalldyr": "crustaceans",
            "nötter": "nuts",
            "nøtter": "nuts",
            "hasselnötter": "hazelnuts",
            "hasselnøtter": "hazelnuts",
            "mandlar": "almonds",
            "mandler": "almonds",
            "cashewnötter": "cashews",
            "cashewnøtter": "cashews",
            "pecannötter": "pecans",
            "pecannøtter": "pecans",
            "paranötter": "brazil nuts",
            "paranøtter": "brazil nuts",
            "macadamianötter": "macadamia nuts",
            "macadamianøtter": "macadamia nuts",
            "tallfrön": "pine nuts",
            "tallfrø": "pine nuts",
            "jordnötter": "peanuts",
            "jordnøtter": "peanuts",
            "senap": "mustard",
            "sennep": "mustard",
            "selleri": "celery",
            "blötdjur": "molluscs",
            "bløtdyr": "molluscs",
            "svaveldioxid": "sulphites",
            "svaveldioksid": "sulphites"
        ]
        
        // Return translated allergen or original if no translation found
        return allergenTranslations[allergenLower] ?? allergen
    }
    
    private func translateIngredientToEnglish(_ ingredient: String) -> String {
        // Simple translation for common ingredients - no duplicates
        let translations: [String: String] = [
            "zucker": "sugar",
            "sucre": "sugar", 
            "azúcar": "sugar",
            "zucchero": "sugar",
            "suiker": "sugar",
            "sukker": "sugar",
            "kakaomasse": "cocoa mass",
            "pâte de cacao": "cocoa mass",
            "pasta de cacao": "cocoa mass",
            "pasta di cacao": "cocoa mass",
            "cacaomassa": "cocoa mass",
            "kakaobutter": "cocoa butter",
            "beurre de cacao": "cocoa butter",
            "manteca de cacao": "cocoa butter",
            "burro di cacao": "cocoa butter",
            "cacaoboter": "cocoa butter",
            "kakaosmør": "cocoa butter",
            "butterreinfett": "butterfat",
            "matière grasse laitière": "butterfat",
            "grasa láctea": "butterfat",
            "grasso del latte": "butterfat",
            "melkvet": "butterfat",
            "melkefett": "butterfat",
            "emulgator": "emulsifier",
            "émulsifiant": "emulsifier",
            "emulgente": "emulsifier",
            "emulsionante": "emulsifier",
            "sojalecithin": "soy lecithin",
            "lécithine de soja": "soy lecithin",
            "lecitina de soja": "soy lecithin",
            "lecitina di soia": "soy lecithin",
            "sojalecithine": "soy lecithin",
            "soyalecitin": "soy lecithin",
            "chili-extrakt": "chili extract",
            "extrait de piment": "chili extract",
            "extracto de chile": "chili extract",
            "estratto di peperoncino": "chili extract",
            "chili-extract": "chili extract",
            "chili-ekstrakt": "chili extract",
            "aromen": "flavors",
            "arômes": "flavors",
            "aromas": "flavors",
            "aromi": "flavors",
            "aroma's": "flavors",
            "aromaer": "flavors"
        ]
        
        return translations[ingredient.lowercased()] ?? ingredient
    }
    
    // OLD FUNCTION - COMMENTED OUT TO AVOID DUPLICATE KEYS
    /*
    private func translateIngredientToEnglish_OLD(_ ingredient: String) -> String {
        let ingredientLower = ingredient.lowercased()
        
        // Comprehensive ingredient translation dictionary (no duplicates)
        let ingredientTranslations: [String: String] = [
            // German ingredients
            "zucker": "sugar",
            "kakaomasse": "cocoa mass",
            "kakaobutter": "cocoa butter",
            "butterreinfett": "butterfat",
            "emulgator": "emulsifier",
            "sojalecithin": "soy lecithin",
            "chili-extrakt": "chili extract",
            "aromen": "flavors",
            "salz": "salt",
            "wasser": "water",
            "mehl": "flour",
            "weizenmehl": "wheat flour",
            "eier": "eggs",
            "milch": "milk",
            "butter": "butter",
            "öl": "oil",
            "sonnenblumenöl": "sunflower oil",
            "palmöl": "palm oil",
            "kokosöl": "coconut oil",
            "hefe": "yeast",
            "backpulver": "baking powder",
            "vanille": "vanilla",
            "zitronensäure": "citric acid",
            "konservierungsstoff": "preservative",
            "farbstoff": "color",
            "süßungsmittel": "sweetener",
            "stabilisator": "stabilizer",
            "verdickungsmittel": "thickener",
            "antioxidationsmittel": "antioxidant",
            
            // French ingredients
            "sucre": "sugar",
            "pâte de cacao": "cocoa mass",
            "beurre de cacao": "cocoa butter",
            "matière grasse laitière": "butterfat",
            "émulsifiant": "emulsifier",
            "lécithine de soja": "soy lecithin",
            "extrait de piment": "chili extract",
            "arômes": "flavors",
            "sel": "salt",
            "eau": "water",
            "farine": "flour",
            "farine de blé": "wheat flour",
            "œufs": "eggs",
            "lait": "milk",
            "beurre": "butter",
            "huile": "oil",
            "huile de tournesol": "sunflower oil",
            "huile de palme": "palm oil",
            "huile de coco": "coconut oil",
            "levure": "yeast",
            "poudre à lever": "baking powder",
            "vanille": "vanilla",
            "acide citrique": "citric acid",
            "conservateur": "preservative",
            "colorant": "color",
            "édulcorant": "sweetener",
            "stabilisant": "stabilizer",
            "épaississant": "thickener",
            "antioxydant": "antioxidant",
            
            // Spanish ingredients
            "azúcar": "sugar",
            "pasta de cacao": "cocoa mass",
            "manteca de cacao": "cocoa butter",
            "grasa láctea": "butterfat",
            "emulgente": "emulsifier",
            "lecitina de soja": "soy lecithin",
            "extracto de chile": "chili extract",
            "aromas": "flavors",
            "sal": "salt",
            "agua": "water",
            "harina": "flour",
            "harina de trigo": "wheat flour",
            "huevos": "eggs",
            "leche": "milk",
            "mantequilla": "butter",
            "aceite": "oil",
            "aceite de girasol": "sunflower oil",
            "aceite de palma": "palm oil",
            "aceite de coco": "coconut oil",
            "levadura": "yeast",
            "levadura en polvo": "baking powder",
            "vainilla": "vanilla",
            "ácido cítrico": "citric acid",
            "conservante": "preservative",
            "colorante": "color",
            "edulcorante": "sweetener",
            "estabilizante": "stabilizer",
            "espesante": "thickener",
            "antioxidante": "antioxidant",
            
            // Italian ingredients
            "zucchero": "sugar",
            "pasta di cacao": "cocoa mass",
            "burro di cacao": "cocoa butter",
            "grasso del latte": "butterfat",
            "emulsionante": "emulsifier",
            "lecitina di soia": "soy lecithin",
            "estratto di peperoncino": "chili extract",
            "aromi": "flavors",
            "sale": "salt",
            "acqua": "water",
            "farina": "flour",
            "farina di frumento": "wheat flour",
            "uova": "eggs",
            "latte": "milk",
            "burro": "butter",
            "olio": "oil",
            "olio di girasole": "sunflower oil",
            "olio di palma": "palm oil",
            "olio di cocco": "coconut oil",
            "lievito": "yeast",
            "lievito in polvere": "baking powder",
            "vaniglia": "vanilla",
            "acido citrico": "citric acid",
            "conservante": "preservative",
            "colorante": "color",
            "dolcificante": "sweetener",
            "stabilizzante": "stabilizer",
            "addensante": "thickener",
            "antiossidante": "antioxidant",
            
            // Dutch ingredients
            "suiker": "sugar",
            "cacaomassa": "cocoa mass",
            "cacaoboter": "cocoa butter",
            "melkvet": "butterfat",
            "sojalecithine": "soy lecithin",
            "chili-extract": "chili extract",
            "aroma's": "flavors",
            "zout": "salt",
            "water": "water",
            "meel": "flour",
            "tarwemeel": "wheat flour",
            "eieren": "eggs",
            "melk": "milk",
            "boter": "butter",
            "olie": "oil",
            "zonnebloemolie": "sunflower oil",
            "palmolie": "palm oil",
            "kokosolie": "coconut oil",
            "gist": "yeast",
            "bakpoeder": "baking powder",
            "vanille": "vanilla",
            "citroenzuur": "citric acid",
            "conserveermiddel": "preservative",
            "kleurstof": "color",
            "zoetstof": "sweetener",
            "stabilisator": "stabilizer",
            "verdikkingsmiddel": "thickener",
            "antioxidant": "antioxidant",
            
            // Norwegian/Swedish/Danish ingredients
            "sukker": "sugar",
            "kakaosmør": "cocoa butter",
            "melkefett": "butterfat",
            "soyalecitin": "soy lecithin",
            "chili-ekstrakt": "chili extract",
            "aromaer": "flavors",
            "salt": "salt",
            "vann": "water",
            "mel": "flour",
            "hvetemel": "wheat flour",
            "egg": "eggs",
            "melk": "milk",
            "smør": "butter",
            "olje": "oil",
            "solsikkeolje": "sunflower oil",
            "palmeolje": "palm oil",
            "kokosnøttolje": "coconut oil",
            "gjær": "yeast",
            "bakepulver": "baking powder",
            "vanilje": "vanilla",
            "sitronsyre": "citric acid",
            "konserveringsmiddel": "preservative",
            "fargestoff": "color",
            "søtningsmiddel": "sweetener",
            "stabilisator": "stabilizer",
            "tykkningsmiddel": "thickener",
            "antioksidant": "antioxidant"
        ]
        
        // Return translated ingredient or original if no translation found
        return ingredientTranslations[ingredientLower] ?? ingredient
    }
    */
    
    init(product: Product, onProductUpdated: @escaping (Product) -> Void, onProductDeleted: ((Product) -> Void)? = nil) {
        self.product = product
        self.onProductUpdated = onProductUpdated
        self.onProductDeleted = onProductDeleted
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Product Name Header
                    VStack(spacing: 8) {
                        Text(product.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    // Product Image Section - Cinematic Display
                    VStack(spacing: 16) {
                        ZStack {
                            // Background stretched images (Color with opacity)
                            Group {
                                if let selectedImage = selectedImage {
                                    // Background image
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(maxWidth: .infinity, maxHeight: 120)
                                        .opacity(0.8)
                                        .blur(radius: 2)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                } else if let imageUrl = product.imageUrl {
                                    // Background for Firebase image
                                    ProductImageView(imageUrl: imageUrl, placeholder: "bag.fill", width: UIScreen.main.bounds.width, height: 120)
                                        .opacity(0.8)
                                        .blur(radius: 2)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                } else {
                                    // Background for fallback
                                    Rectangle()
                                        .fill(Color.appItemBackground)
                                        .frame(maxWidth: .infinity, maxHeight: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            
                            // Center main image
                            Group {
                                if let selectedImage = selectedImage {
                                    // Local image data (from scanning or photo library)
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                                } else if let imageUrl = product.imageUrl {
                                    // Firebase Storage image
                                    ProductImageView(imageUrl: imageUrl, placeholder: "bag.fill", width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                                } else if let iconName = selectedIconName {
                                    Image(systemName: iconName)
                                        .font(.system(size: 40))
                                        .foregroundColor(.blue)
                                        .frame(width: 100, height: 100)
                                        .background(Color.blue.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                                } else {
                                    Image(systemName: "bag.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.blue)
                                        .frame(width: 100, height: 100)
                                        .background(Color.blue.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: 120)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    
                    // STORE PRICES Section
                    if let multiStore = multiStoreProduct, !multiStore.storePrices.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("PRICE")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 28)
                                .padding(.bottom, 8)
                            
                            LazyVStack(spacing: 0) {
                                ForEach(multiStore.sortedStorePrices, id: \.id) { storePrice in
                                    Button(action: {
                                        // Could implement store selection here if needed
                                    }) {
                                        HStack(spacing: 16) {
                                            // Store Logo
                                            if let store = Store.knownStores.first(where: { $0.name == storePrice.store }) {
                                                Image(store.logoName)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 44, height: 44)
                                                    .frame(width: 60, height: 60)
                                                    .background(Color.gray.opacity(0.1))
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                            } else {
                                                Image(systemName: "storefront")
                                                    .font(.system(size: 24, weight: .medium))
                                                    .foregroundColor(.blue)
                                                    .frame(width: 60, height: 60)
                                                    .background(Color.blue.opacity(0.1))
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                            }
                                            
                                            // Store info
                                            VStack(alignment: .leading, spacing: 4) {
                                                HStack {
                                                    Text(storePrice.store)
                                                        .font(.system(size: 16, weight: .medium))
                                                        .foregroundColor(.primary)
                                                    
                                                    // Best price indicator
                                                    if storePrice.price == multiStore.lowestPrice {
                                                        Text("BEST PRICE")
                                                            .font(.system(size: 10, weight: .bold))
                                                            .foregroundColor(.white)
                                                            .padding(.horizontal, 8)
                                                            .padding(.vertical, 2)
                                                            .background(Color.green)
                                                            .cornerRadius(4)
                                                    }
                                                    
                                                    Spacer()
                                                    
                                                    Text("\(getCurrencySymbol(for: defaultCurrency)) \(String(format: "%.2f", storePrice.price))")
                                                        .font(.system(size: 18, weight: .bold))
                                                        .foregroundColor(storePrice.price == multiStore.lowestPrice ? .green : .primary)
                                                }
                                                
                                                Text("Updated \(formatDate(storePrice.date))")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 16)
                                        .background(Color.appItemBackground)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    if storePrice.id != multiStore.sortedStorePrices.last?.id {
                                        Divider()
                                            .padding(.leading, 76)
                                    }
                                }
                            }
                            .background(Color.appItemBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray5), lineWidth: 1)
                            )
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 20)
                    }
                    
                    // NUTRITIONAL INFORMATION Section
                    if let nutriscoreGrade = product.nutriscoreGrade {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("NUTRITION")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 28)
                                .padding(.bottom, 8)
                            
                            NutriScoreView(grade: nutriscoreGrade, nutritionalInfo: product.nutritionalInfo)
                                .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 20)
                    }
                    
                    // ALLERGENS Section - Always show for debugging
                    VStack(alignment: .leading, spacing: 0) {
                        Text("ALLERGENS")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 28)
                            .padding(.bottom, 8)
                        
                        VStack(spacing: 0) {
                            // Allergens Information
                            if let allergens = product.allergens, !allergens.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Allergens")
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.top, 16)
                                    
                                    // Display individual allergens with conditional coloring
                                    let cleanedAllergens = cleanAllergenText(allergens) ?? allergens
                                    let allergenList = cleanedAllergens.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                                    
                                    HStack(alignment: .top, spacing: 4) {
                                        ForEach(Array(allergenList.enumerated()), id: \.offset) { index, allergen in
                                            let isUserAllergen = AllergyManager.shared.userAllergies.contains { userAllergen in
                                                allergen.lowercased().contains(userAllergen.lowercased()) || 
                                                userAllergen.lowercased().contains(allergen.lowercased())
                                            }
                                            
                                            Text(allergen)
                                                .font(.body)
                                                .foregroundColor(isUserAllergen ? .red : .secondary)
                                            
                                            if index < allergenList.count - 1 {
                                                Text(",")
                                                    .font(.body)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 16)
                                }
                            }
                            
                            // Traces Information
                            if let traces = product.traces, !traces.isEmpty {
                                if product.allergens != nil && !product.allergens!.isEmpty {
                                    Divider()
                                        .padding(.leading, 20)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("May contain traces of")
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.top, 16)
                                    
                                    // Display individual trace allergens with conditional coloring
                                    let cleanedTraces = cleanAllergenText(traces) ?? traces
                                    let traceList = cleanedTraces.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                                    
                                    HStack(alignment: .top, spacing: 4) {
                                        ForEach(Array(traceList.enumerated()), id: \.offset) { index, trace in
                                            let isUserAllergen = AllergyManager.shared.userAllergies.contains { userAllergen in
                                                trace.lowercased().contains(userAllergen.lowercased()) || 
                                                userAllergen.lowercased().contains(trace.lowercased())
                                            }
                                            
                                            Text(trace)
                                                .font(.body)
                                                .foregroundColor(isUserAllergen ? .red : .secondary)
                                            
                                            if index < traceList.count - 1 {
                                                Text(",")
                                                    .font(.body)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 16)
                                }
                            }
                            
                            // Ingredients Information
                            if let ingredients = product.ingredients, !ingredients.isEmpty {
                                let hasPreviousContent = (product.allergens != nil && !product.allergens!.isEmpty) || (product.traces != nil && !product.traces!.isEmpty)
                                if hasPreviousContent {
                                    Divider()
                                        .padding(.leading, 20)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Ingredients")
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.top, 16)
                                    
                                    Text(cleanIngredientsText(ingredients) ?? ingredients)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                        .padding(.horizontal, 20)
                                        .padding(.bottom, 16)
                                }
                            }
                            
                            
                        }
                        .background(Color.appItemBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray5), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 20)
                    
                    // PRODUCT INFORMATION Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("PRODUCT")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.bottom, 8)
                        
                        VStack(spacing: 0) {
                            // Product Name
                            HStack {
                                Text("Product Name")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(productName.isEmpty ? "From API" : String(productName.prefix(32)))
                                    .multilineTextAlignment(.trailing)
                                    .foregroundColor(productName.isEmpty ? .secondary : .primary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.appFieldBackground.opacity(0.5))
                            
                            Divider()
                                .padding(.leading, 20)
                            
                            // Brand
                            HStack {
                                Text("Brand")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(brand.isEmpty ? "From API" : brand)
                                    .multilineTextAlignment(.trailing)
                                    .foregroundColor(brand.isEmpty ? .secondary : .primary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.appFieldBackground.opacity(0.5))
                            
                            Divider()
                                .padding(.leading, 20)
                            
                            // Category
                            HStack {
                                Text("Category")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(category.isEmpty ? "From API" : category)
                                    .multilineTextAlignment(.trailing)
                                    .foregroundColor(category.isEmpty ? .secondary : .primary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.appFieldBackground.opacity(0.5))
                        }
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray5), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    
                    
                    
                    // Product Status
                    if isLoadingProduct {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Searching for product...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    } else if productFound {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Product detected")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    
                    // DELETE PRODUCT Section (if onProductDeleted is provided)
                    if onProductDeleted != nil {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("DANGER ZONE")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 8)
                            
                            VStack(spacing: 0) {
                                Button(action: {
                                    showingDeleteAlert = true
                                }) {
                                    HStack {
                                        Text("Delete Product")
                                            .font(.body)
                                            .foregroundColor(.red)
                                        Spacer()
                                        Image(systemName: "trash.fill")
                                            .foregroundColor(.red)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(Color.appFieldBackground)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray5), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Close")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage, selectedIconName: $selectedIconName)
        }
        .sheet(isPresented: $showingIconPicker) {
            IconPickerView(
                selectedIconName: $selectedIconName,
                selectedImage: $selectedImage,
                isPresented: $showingIconPicker
            )
        }
        .onAppear {
            print("DEBUG: EditProductView - Product: \(product.name)")
            print("DEBUG: EditProductView - Nutri-Score: \(product.nutriscoreGrade ?? "nil")")
            print("DEBUG: EditProductView - Nutritional Info: \(product.nutritionalInfo != nil ? "Available" : "nil")")
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .alert("Delete Product", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteProduct()
            }
        } message: {
            Text("Are you sure you want to delete this product? This action cannot be undone.")
        }
        .actionSheet(isPresented: $showingImageMenu) {
            ActionSheet(
                title: Text("Select Image Source"),
                buttons: [
                    .default(Text("Photo Library")) {
                        selectedIconName = nil
                        showingImagePicker = true
                    },
                    .default(Text("Choose Icon")) {
                        showingIconPicker = true
                    },
                    .cancel()
                ]
            )
        }
        .onAppear {
            // Pre-fill form with existing product data
            productName = product.name
            brand = product.brand ?? ""
            category = product.category
            barcode = product.barcode ?? ""
            selectedIconName = product.iconName
            
            // Load image data
            if let imageData = product.imageData {
                selectedImage = UIImage(data: imageData)
            } else if let imageUrl = product.imageUrl {
                // Load image from Firebase Storage
                FirebaseStorageManager.shared.downloadAndCacheImage(from: imageUrl) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let data):
                            selectedImage = UIImage(data: data)
                        case .failure(let error):
                            print("DEBUG: Error loading product image in EditProductView: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    
    private func searchProductByBarcode() {
        guard !barcode.isEmpty else { return }
        
        isLoadingProduct = true
        productFound = false
        
        Task {
            let result = await apiService.searchProductWithImage(barcode: barcode)
            
            await MainActor.run {
                isLoadingProduct = false
                
                switch result {
                case .found(let productData):
                    productName = productData.name
                    brand = productData.brand ?? ""
                    category = productData.category
                    
                    // Set the image if available
                    if let imageData = productData.imageData {
                        selectedImage = UIImage(data: imageData)
                    }
                    
                    productFound = true
                case .notFound:
                    productFound = false
                    alertMessage = "Product not found in database. Please enter details manually."
                    showingAlert = true
                case .error(let errorMessage):
                    productFound = false
                    alertMessage = "Error searching product: \(errorMessage)"
                    showingAlert = true
                }
            }
        }
    }
    
    
    private func deleteProduct() {
        onProductDeleted?(product)
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    EditProductView(product: Product.sampleProducts[0]) { _ in }
}
