//
//  AddProductView.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 10/09/2025.
//

import SwiftUI

struct AddProductView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var apiService = ProductAPIService.shared
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
    @AppStorage("lastSelectedCategory") private var category = ""
    @State private var barcode = ""
    @AppStorage("lastSelectedStore") private var storeName = ""
    @State private var showingStorePicker = false
    @State private var price = ""
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
    @State private var showingImageMenu = false
    @State private var scannedNutriscoreGrade: String?
    @State private var scannedNutritionalInfo: NutritionalInfo?
    @State private var scannedIngredients: String?
    @State private var scannedAllergens: String?
    @State private var scannedTraces: String?
    @FocusState private var isPriceFieldFocused: Bool
    
    let onProductAdded: (Product) -> Void
    
    private let categories = ["Produce", "Dairy", "Meat", "Bakery", "Beverages", "Snacks", "Household", "Electronics", "Other"]
    
    // Check if all required fields are filled (except price)
    private var allFieldsFilled: Bool {
        return !storeName.isEmpty && 
               !barcode.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Product Image Section
                    VStack(spacing: 16) {
                        Button(action: {
                            showingImageMenu = true
                        }) {
                            Group {
                                if let selectedImage = selectedImage {
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                } else if let iconName = selectedIconName {
                                    Image(systemName: iconName)
                                        .font(.system(size: 32))
                                        .foregroundColor(.blue)
                                        .frame(width: 80, height: 80)
                                        .background(Color.blue.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                } else {
                                    Image(systemName: "bag.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.blue)
                                        .frame(width: 80, height: 80)
                                        .background(Color.blue.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                    
                    // PRODUCT INFORMATION Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("PRODUCT INFORMATION")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)
                        
                        VStack(spacing: 0) {
                            // Product Name
                            HStack {
                                Text("Product Name")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(productName.isEmpty ? "From API" : productName)
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
                    
                    // STORE & PRICE Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("STORE & PRICE")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)
                        
                        VStack(spacing: 0) {
                            // Store Name
                            HStack {
                                Text("Store")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                                Button(action: {
                                    showingStorePicker = true
                                }) {
                                    if !storeName.isEmpty {
                                        Text(storeName)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.blue)
                                    } else {
                                        Text("Select")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.green)
                                            .cornerRadius(8)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.appFieldBackground.opacity(0.5))
                            
                            Divider()
                                .padding(.leading, 20)
                            
                            // Price
                            HStack {
                                Text("Price")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                                HStack(spacing: 4) {
                                    TextField("0.00", text: $price)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundColor(.blue)
                                        .keyboardType(.decimalPad)
                                        .focused($isPriceFieldFocused)
                                    Text(getCurrencySymbol(for: defaultCurrency))
                                        .foregroundColor(.blue)
                                }
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
                            Text("Product detected  ")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
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
                        saveProduct()
                    }) {
                        Text("Save Product")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isFormValid ? Color.green : Color.gray)
                            .cornerRadius(8)
                    }
                    .disabled(!isFormValid)
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
        .sheet(isPresented: $showingStorePicker) {
            StorePickerView(selectedStore: $storeName)
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
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
        .onChange(of: allFieldsFilled) { isFilled in
            if isFilled {
                // Focus on price field when all other fields are filled
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isPriceFieldFocused = true
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        return !storeName.isEmpty && !price.isEmpty && Double(price) != nil
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
                    
                    // Store nutritional data
                    scannedNutriscoreGrade = productData.nutriscoreGrade
                    scannedNutritionalInfo = productData.nutritionalInfo
                    scannedIngredients = productData.ingredients
                    scannedAllergens = productData.allergens
                    scannedTraces = productData.traces
                    
                    
                    // Debug nutritional data
                    print("DEBUG: Nutri-Score Grade: \(productData.nutriscoreGrade ?? "nil")")
                    print("DEBUG: Nutritional Info: \(productData.nutritionalInfo != nil ? "Available" : "nil")")
                    
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
    
    
    private func saveProduct() {
        guard let priceValue = Double(price) else {
            alertMessage = "Please enter a valid price"
            showingAlert = true
            return
        }
        
        let newProduct = Product(
            name: productName,
            brand: brand.isEmpty ? nil : brand,
            category: category,
            barcode: barcode.isEmpty ? nil : barcode,
            store: storeName,
            price: priceValue,
            date: Date(),
            imageData: selectedImage?.jpegData(compressionQuality: 0.8),
            iconName: selectedIconName,
            isChecked: false,
            isInShoppingList: false, // Explicitly ensure new products are NOT in shopping list
            nutriscoreGrade: scannedNutriscoreGrade,
            nutritionalInfo: scannedNutritionalInfo,
            ingredients: scannedIngredients,
            allergens: scannedAllergens,
            traces: scannedTraces
        )
        
        
        onProductAdded(newProduct)
        
        presentationMode.wrappedValue.dismiss()
    }
}

// AddProductView with initial barcode for scan flow
struct AddProductViewWithBarcode: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var apiService = ProductAPIService.shared
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
    @AppStorage("lastSelectedCategory") private var category = ""
    @State private var barcode = ""
    @AppStorage("lastSelectedStore") private var storeName = ""
    @State private var showingStorePicker = false
    @State private var price = ""
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
    @State private var showingImageMenu = false
    @State private var scannedNutriscoreGrade: String?
    @State private var scannedNutritionalInfo: NutritionalInfo?
    @State private var scannedIngredients: String?
    @State private var scannedAllergens: String?
    @State private var scannedTraces: String?
    @FocusState private var isPriceFieldFocused: Bool
    
    let initialBarcode: String
    let onProductAdded: (Product) -> Void
    let onScanAgain: (() -> Void)?
    
    private let categories = ["Produce", "Dairy", "Meat", "Bakery", "Beverages", "Snacks", "Household", "Electronics", "Other"]
    
    // Check if all required fields are filled (except price)
    private var allFieldsFilled: Bool {
        return !storeName.isEmpty && 
               !barcode.isEmpty
    }
    
    init(initialBarcode: String, onProductAdded: @escaping (Product) -> Void, onScanAgain: (() -> Void)? = nil) {
        self.initialBarcode = initialBarcode
        self.onProductAdded = onProductAdded
        self.onScanAgain = onScanAgain
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Product Image Section
                    VStack(spacing: 16) {
                        Button(action: {
                            showingImageMenu = true
                        }) {
                            Group {
                                if let selectedImage = selectedImage {
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                } else if let iconName = selectedIconName {
                                    Image(systemName: iconName)
                                        .font(.system(size: 32))
                                        .foregroundColor(.blue)
                                        .frame(width: 80, height: 80)
                                        .background(Color.blue.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                } else {
                                    Image(systemName: "bag.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.blue)
                                        .frame(width: 80, height: 80)
                                        .background(Color.blue.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                    
                    // PRODUCT INFORMATION Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("PRODUCT INFORMATION")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)
                        
                        VStack(spacing: 0) {
                            // Product Name
                            HStack {
                                Text("Product Name")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(productName.isEmpty ? "From API" : productName)
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
                    
                    // STORE & PRICE Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("STORE & PRICE")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)
                        
                        VStack(spacing: 0) {
                            // Store Name
                            HStack {
                                Text("Store")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                                Button(action: {
                                    showingStorePicker = true
                                }) {
                                    if !storeName.isEmpty {
                                        Text(storeName)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.blue)
                                    } else {
                                        Text("Select")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.green)
                                            .cornerRadius(8)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.appFieldBackground.opacity(0.5))
                            
                            Divider()
                                .padding(.leading, 20)
                            
                            // Price
                            HStack {
                                Text("Price")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                                HStack(spacing: 4) {
                                    TextField("0.00", text: $price)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundColor(.blue)
                                        .keyboardType(.decimalPad)
                                        .focused($isPriceFieldFocused)
                                    Text(getCurrencySymbol(for: defaultCurrency))
                                        .foregroundColor(.blue)
                                }
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
                    
                    // Scan Again Button
                    if let onScanAgain = onScanAgain {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                            onScanAgain()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "barcode.viewfinder")
                                    .font(.system(size: 20, weight: .medium))
                                Text("Scan Again")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.blue)
                            .cornerRadius(16)
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
                        saveProduct()
                    }) {
                        Text("Save Product")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isFormValid ? Color.green : Color.gray)
                            .cornerRadius(8)
                    }
                    .disabled(!isFormValid)
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
        .sheet(isPresented: $showingStorePicker) {
            StorePickerView(selectedStore: $storeName)
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
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
            // Set initial barcode and search for product
            barcode = initialBarcode
            if !initialBarcode.isEmpty {
                searchProductByBarcode()
            }
        }
        .onChange(of: allFieldsFilled) { isFilled in
            if isFilled {
                // Focus on price field when all other fields are filled
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isPriceFieldFocused = true
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        return !storeName.isEmpty && !price.isEmpty && Double(price) != nil
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
                    
                    // Store nutritional data
                    scannedNutriscoreGrade = productData.nutriscoreGrade
                    scannedNutritionalInfo = productData.nutritionalInfo
                    scannedIngredients = productData.ingredients
                    scannedAllergens = productData.allergens
                    scannedTraces = productData.traces
                    
                    
                    // Debug nutritional data
                    print("DEBUG: Nutri-Score Grade: \(productData.nutriscoreGrade ?? "nil")")
                    print("DEBUG: Nutritional Info: \(productData.nutritionalInfo != nil ? "Available" : "nil")")
                    
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
    
    private func saveProduct() {
        guard let priceValue = Double(price) else {
            alertMessage = "Please enter a valid price"
            showingAlert = true
            return
        }
        
        let newProduct = Product(
            name: productName,
            brand: brand.isEmpty ? nil : brand,
            category: category,
            barcode: barcode.isEmpty ? nil : barcode,
            store: storeName,
            price: priceValue,
            date: Date(),
            imageData: selectedImage?.jpegData(compressionQuality: 0.8),
            iconName: selectedIconName,
            isChecked: false,
            isInShoppingList: false, // Explicitly ensure new products are NOT in shopping list
            nutriscoreGrade: scannedNutriscoreGrade,
            nutritionalInfo: scannedNutritionalInfo,
            ingredients: scannedIngredients,
            allergens: scannedAllergens,
            traces: scannedTraces
        )
        
        
        onProductAdded(newProduct)
        
        presentationMode.wrappedValue.dismiss()
    }
}


#Preview {
    AddProductView { _ in }
}
