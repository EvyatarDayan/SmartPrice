//
//  CurrencySelectionView.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 10/09/2025.
//

import SwiftUI

struct CurrencySelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCurrency: String
    
    @State private var searchText = ""
    
    // Comprehensive list of world currencies (no duplicates)
    private let allCurrencies = [
        ("USD", "🇺🇸", "US Dollar"),
        ("EUR", "🇪🇺", "Euro"),
        ("GBP", "🇬🇧", "British Pound"),
        ("JPY", "🇯🇵", "Japanese Yen"),
        ("CAD", "🇨🇦", "Canadian Dollar"),
        ("AUD", "🇦🇺", "Australian Dollar"),
        ("CHF", "🇨🇭", "Swiss Franc"),
        ("CNY", "🇨🇳", "Chinese Yuan"),
        ("SEK", "🇸🇪", "Swedish Krona"),
        ("NZD", "🇳🇿", "New Zealand Dollar"),
        ("MXN", "🇲🇽", "Mexican Peso"),
        ("SGD", "🇸🇬", "Singapore Dollar"),
        ("HKD", "🇭🇰", "Hong Kong Dollar"),
        ("NOK", "🇳🇴", "Norwegian Krone"),
        ("KRW", "🇰🇷", "South Korean Won"),
        ("TRY", "🇹🇷", "Turkish Lira"),
        ("RUB", "🇷🇺", "Russian Ruble"),
        ("INR", "🇮🇳", "Indian Rupee"),
        ("BRL", "🇧🇷", "Brazilian Real"),
        ("ZAR", "🇿🇦", "South African Rand"),
        ("ILS", "🇮🇱", "Israeli Shekel"),
        ("AED", "🇦🇪", "UAE Dirham"),
        ("SAR", "🇸🇦", "Saudi Riyal"),
        ("PLN", "🇵🇱", "Polish Złoty"),
        ("THB", "🇹🇭", "Thai Baht"),
        ("IDR", "🇮🇩", "Indonesian Rupiah"),
        ("CZK", "🇨🇿", "Czech Koruna"),
        ("HUF", "🇭🇺", "Hungarian Forint"),
        ("CLP", "🇨🇱", "Chilean Peso"),
        ("PHP", "🇵🇭", "Philippine Peso"),
        ("MYR", "🇲🇾", "Malaysian Ringgit"),
        ("COP", "🇨🇴", "Colombian Peso"),
        ("RON", "🇷🇴", "Romanian Leu"),
        ("VND", "🇻🇳", "Vietnamese Dong"),
        ("EGP", "🇪🇬", "Egyptian Pound"),
        ("UAH", "🇺🇦", "Ukrainian Hryvnia"),
        ("ARS", "🇦🇷", "Argentine Peso"),
        ("QAR", "🇶🇦", "Qatari Riyal"),
        ("KWD", "🇰🇼", "Kuwaiti Dinar"),
        ("BDT", "🇧🇩", "Bangladeshi Taka"),
        ("NGN", "🇳🇬", "Nigerian Naira"),
        ("MAD", "🇲🇦", "Moroccan Dirham"),
        ("PKR", "🇵🇰", "Pakistani Rupee"),
        ("DKK", "🇩🇰", "Danish Krone"),
        ("BGN", "🇧🇬", "Bulgarian Lev"),
        ("HRK", "🇭🇷", "Croatian Kuna"),
        ("RSD", "🇷🇸", "Serbian Dinar"),
        ("ISK", "🇮🇸", "Icelandic Króna"),
        ("LKR", "🇱🇰", "Sri Lankan Rupee"),
        ("TND", "🇹🇳", "Tunisian Dinar"),
        ("JOD", "🇯🇴", "Jordanian Dinar"),
        ("OMR", "🇴🇲", "Omani Rial"),
        ("BHD", "🇧🇭", "Bahraini Dinar"),
        ("LBP", "🇱🇧", "Lebanese Pound"),
        ("KHR", "🇰🇭", "Cambodian Riel"),
        ("MMK", "🇲🇲", "Myanmar Kyat"),
        ("LAK", "🇱🇦", "Lao Kip"),
        ("MNT", "🇲🇳", "Mongolian Tögrög"),
        ("NPR", "🇳🇵", "Nepalese Rupee"),
        ("KZT", "🇰🇿", "Kazakhstani Tenge"),
        ("UZS", "🇺🇿", "Uzbekistani Som"),
        ("GEL", "🇬🇪", "Georgian Lari"),
        ("AMD", "🇦🇲", "Armenian Dram"),
        ("AZN", "🇦🇿", "Azerbaijani Manat"),
        ("BYN", "🇧🇾", "Belarusian Ruble"),
        ("MDL", "🇲🇩", "Moldovan Leu"),
        ("TJS", "🇹🇯", "Tajikistani Somoni"),
        ("TMT", "🇹🇲", "Turkmenistani Manat"),
        ("KGS", "🇰🇬", "Kyrgyzstani Som"),
        ("AFN", "🇦🇫", "Afghan Afghani"),
        ("IRR", "🇮🇷", "Iranian Rial"),
        ("IQD", "🇮🇶", "Iraqi Dinar"),
        ("YER", "🇾🇪", "Yemeni Rial"),
        ("SYP", "🇸🇾", "Syrian Pound"),
        ("LYD", "🇱🇾", "Libyan Dinar"),
        ("SDG", "🇸🇩", "Sudanese Pound"),
        ("ETB", "🇪🇹", "Ethiopian Birr"),
        ("KES", "🇰🇪", "Kenyan Shilling"),
        ("UGX", "🇺🇬", "Ugandan Shilling"),
        ("TZS", "🇹🇿", "Tanzanian Shilling"),
        ("GHS", "🇬🇭", "Ghanaian Cedi"),
        ("XOF", "🇨🇮", "West African CFA Franc"),
        ("XAF", "🇨🇲", "Central African CFA Franc"),
        ("ZMW", "🇿🇲", "Zambian Kwacha"),
        ("MWK", "🇲🇼", "Malawian Kwacha"),
        ("BWP", "🇧🇼", "Botswana Pula"),
        ("NAD", "🇳🇦", "Namibian Dollar"),
        ("MUR", "🇲🇺", "Mauritian Rupee"),
        ("SCR", "🇸🇨", "Seychellois Rupee"),
        ("MVR", "🇲🇻", "Maldivian Rufiyaa"),
        ("BND", "🇧🇳", "Brunei Dollar"),
        ("KYD", "🇰🇾", "Cayman Islands Dollar"),
        ("BBD", "🇧🇧", "Barbadian Dollar"),
        ("JMD", "🇯🇲", "Jamaican Dollar"),
        ("TTD", "🇹🇹", "Trinidad and Tobago Dollar"),
        ("GYD", "🇬🇾", "Guyanese Dollar"),
        ("SRD", "🇸🇷", "Surinamese Dollar"),
        ("FJD", "🇫🇯", "Fijian Dollar"),
        ("WST", "🇼🇸", "Samoan Tālā"),
        ("TOP", "🇹🇴", "Tongan Paʻanga"),
        ("VUV", "🇻🇺", "Vanuatu Vatu"),
        ("SBD", "🇸🇧", "Solomon Islands Dollar"),
        ("PGK", "🇵🇬", "Papua New Guinean Kina"),
        ("KID", "🇰🇮", "Kiribati Dollar"),
        ("TVD", "🇹🇻", "Tuvaluan Dollar"),
        ("NIO", "🇳🇮", "Nicaraguan Córdoba"),
        ("HNL", "🇭🇳", "Honduran Lempira"),
        ("GTQ", "🇬🇹", "Guatemalan Quetzal"),
        ("BZD", "🇧🇿", "Belize Dollar"),
        ("SVC", "🇸🇻", "Salvadoran Colón"),
        ("CRC", "🇨🇷", "Costa Rican Colón"),
        ("PAB", "🇵🇦", "Panamanian Balboa"),
        ("PYG", "🇵🇾", "Paraguayan Guaraní"),
        ("UYU", "🇺🇾", "Uruguayan Peso"),
        ("BOB", "🇧🇴", "Bolivian Boliviano"),
        ("PEN", "🇵🇪", "Peruvian Sol"),
        ("ECU", "🇪🇨", "Ecuadorian Sucre"),
        ("VEF", "🇻🇪", "Venezuelan Bolívar")
    ]
    
    private var filteredCurrencies: [(String, String, String)] {
        if searchText.isEmpty {
            return allCurrencies
        } else {
            return allCurrencies.filter { currency in
                currency.0.lowercased().contains(searchText.lowercased()) ||
                currency.1.lowercased().contains(searchText.lowercased()) ||
                currency.2.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List(filteredCurrencies, id: \.0) { currency in
                Button(action: {
                    selectedCurrency = currency.0
                    dismiss()
                }) {
                    HStack {
                        Text(currency.1)
                            .font(.title2)
                        Text(currency.0)
                            .font(.headline)
                        Text(currency.2)
                            .foregroundColor(.gray)
                        Spacer()
                        if currency.0 == selectedCurrency {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search Currency")
            .navigationTitle("Select Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CurrencySelectionView(selectedCurrency: .constant("USD"))
}