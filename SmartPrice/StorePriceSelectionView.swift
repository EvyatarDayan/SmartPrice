//
//  StorePriceSelectionView.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 18/09/2025.
//

import SwiftUI

struct StorePriceSelectionView: View {
    let storePrices: [StorePrice]
    @Binding var selectedStore: String
    @Binding var selectedPrice: Double
    @AppStorage("defaultCurrency") private var defaultCurrency: String = "EUR"
    @Environment(\.presentationMode) var presentationMode
    
    private func getCurrencySymbol(for currency: String) -> String {
        switch currency {
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        case "SEK": return "kr"
        case "AUD": return "A$"
        case "CAD": return "C$"
        case "CHF": return "CHF"
        case "CNY": return "¥"
        case "HKD": return "HK$"
        case "INR": return "₹"
        case "KRW": return "₩"
        case "MXN": return "$"
        case "NZD": return "NZ$"
        case "SGD": return "S$"
        case "THB": return "฿"
        case "TRY": return "₺"
        case "ZAR": return "R"
        case "AED": return "د.إ"
        case "SAR": return "﷼"
        case "QAR": return "﷼"
        case "KWD": return "د.ك"
        case "BHD": return ".د.ب"
        case "OMR": return "ر.ع."
        case "EGP": return "£"
        case "ILS": return "₪"
        case "RUB": return "₽"
        case "PLN": return "zł"
        case "HUF": return "Ft"
        case "CZK": return "Kč"
        case "DKK": return "kr."
        case "NOK": return "kr"
        case "BRL": return "R$"
        case "CLP": return "$"
        case "COP": return "$"
        case "PEN": return "S/."
        case "ARS": return "$"
        case "UYU": return "$"
        case "PYG": return "₲"
        case "DOP": return "RD$"
        case "CRC": return "₡"
        case "GTQ": return "Q"
        case "HNL": return "L"
        case "NIO": return "C$"
        case "PAB": return "B/."
        case "VES": return "Bs"
        case "BOB": return "Bs."
        case "SRD": return "$"
        default: return "$"
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(storePrices.sorted(by: { $0.price < $1.price }), id: \.id) { storePrice in
                        Button(action: {
                            selectedStore = storePrice.store
                            selectedPrice = storePrice.price
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack(spacing: 16) {
                                // Store Logo
                                if let store = Store.knownStores.first(where: { $0.name == storePrice.store }) {
                                    Image(store.logoName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 40, height: 40)
                                        .cornerRadius(8)
                                } else {
                                    Image(systemName: "storefront")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.blue)
                                        .frame(width: 40, height: 40)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                }
                                
                                // Store info
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(storePrice.store)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.primary)
                                        
                                        // Best price indicator
                                        if storePrice.price == storePrices.map(\.price).min() {
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
                                            .foregroundColor(storePrice.price == storePrices.map(\.price).min() ? .green : .primary)
                                    }
                                    
                                    Text("Updated \(formatDate(storePrice.date))")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                
                                // Selection indicator
                                if selectedStore == storePrice.store {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color.appItemBackground)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if storePrice.id != storePrices.sorted(by: { $0.price < $1.price }).last?.id {
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
                .padding(.top, 20)
            }
            .background(Color.appBackground)
            .navigationTitle("Select Store & Price")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    StorePriceSelectionView(
        storePrices: [
            StorePrice(store: "ICA", price: 29.90, date: Date()),
            StorePrice(store: "Coop", price: 32.50, date: Date().addingTimeInterval(-86400)),
            StorePrice(store: "Willys", price: 28.75, date: Date().addingTimeInterval(-172800))
        ],
        selectedStore: .constant("ICA"),
        selectedPrice: .constant(29.90)
    )
}
