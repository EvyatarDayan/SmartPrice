import Foundation
import SwiftUI
import Combine

class CurrencyManager: ObservableObject {
    static let shared = CurrencyManager()
    
    @Published var defaultCurrency: String {
        didSet {
            UserDefaults.standard.set(defaultCurrency, forKey: "defaultCurrency")
        }
    }
    
    @Published var isLocationBasedCurrencyEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isLocationBasedCurrencyEnabled, forKey: "isLocationBasedCurrencyEnabled")
            if isLocationBasedCurrencyEnabled {
                updateCurrencyBasedOnLocation()
            }
        }
    }
    
    private let locationManager = LocationManager.shared
    private let locationToCurrencyMapper = LocationToCurrencyMapper.shared
    
    private init() {
        self.defaultCurrency = UserDefaults.standard.string(forKey: "defaultCurrency") ?? "EUR"
        self.isLocationBasedCurrencyEnabled = UserDefaults.standard.bool(forKey: "isLocationBasedCurrencyEnabled")
        
        // Set up location-based currency updates
        setupLocationBasedCurrency()
    }
    
    init(currency: String) {
        self.defaultCurrency = currency
        self.isLocationBasedCurrencyEnabled = false
    }
    
    // MARK: - Location-Based Currency Methods
    
    private func setupLocationBasedCurrency() {
        // Listen for location updates
        locationManager.$currentCity
            .combineLatest(locationManager.$currentCountry)
            .sink { [weak self] city, country in
                if self?.isLocationBasedCurrencyEnabled == true {
                    self?.updateCurrencyBasedOnLocation()
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    func updateCurrencyBasedOnLocation() {
        guard isLocationBasedCurrencyEnabled else { return }
        
        let detectedCurrency = locationToCurrencyMapper.getCurrencyForLocation(
            city: locationManager.currentCity,
            country: locationManager.currentCountry
        )
        
        if let currency = detectedCurrency, currency != defaultCurrency {
            print("DEBUG: Updating currency from \(defaultCurrency) to \(currency) based on location")
            defaultCurrency = currency
        }
    }
    
    func requestLocationPermissionAndUpdateCurrency() {
        locationManager.requestLocationPermission()
    }
    
    func getCurrentLocationString() -> String {
        return locationManager.getCurrentLocationString()
    }
    
    func isLocationPermissionGranted() -> Bool {
        return locationManager.locationPermissionStatus == .authorizedWhenInUse || 
               locationManager.locationPermissionStatus == .authorizedAlways
    }
    
    func getCurrencySymbol() -> String {
        return getCurrencySymbol(for: defaultCurrency)
    }
    
    func getCurrencySymbol(for currency: String) -> String {
        switch currency {
        case "USD":
            return "$"
        case "EUR":
            return "€"
        case "GBP":
            return "£"
        case "JPY":
            return "¥"
        case "CAD":
            return "C$"
        case "AUD":
            return "A$"
        case "CHF":
            return "CHF"
        case "CNY":
            return "¥"
        case "SEK":
            return "kr"
        case "NZD":
            return "NZ$"
        case "MXN":
            return "$"
        case "SGD":
            return "S$"
        case "HKD":
            return "HK$"
        case "NOK":
            return "kr"
        case "KRW":
            return "₩"
        case "TRY":
            return "₺"
        case "RUB":
            return "₽"
        case "INR":
            return "₹"
        case "BRL":
            return "R$"
        case "ZAR":
            return "R"
        case "ILS":
            return "₪"
        case "AED":
            return "د.إ"
        case "SAR":
            return "ر.س"
        case "PLN":
            return "zł"
        case "THB":
            return "฿"
        case "IDR":
            return "Rp"
        case "CZK":
            return "Kč"
        case "HUF":
            return "Ft"
        case "CLP":
            return "$"
        case "PHP":
            return "₱"
        case "MYR":
            return "RM"
        case "COP":
            return "$"
        case "RON":
            return "lei"
        case "VND":
            return "₫"
        case "EGP":
            return "E£"
        case "UAH":
            return "₴"
        case "ARS":
            return "$"
        case "QAR":
            return "ر.ق"
        case "KWD":
            return "د.ك"
        case "BDT":
            return "৳"
        case "NGN":
            return "₦"
        case "MAD":
            return "د.م."
        case "PKR":
            return "₨"
        case "DKK":
            return "kr"
        case "BGN":
            return "лв"
        case "HRK":
            return "kn"
        case "RSD":
            return "дин"
        case "ISK":
            return "kr"
        case "LKR":
            return "Rs"
        case "TND":
            return "د.ت"
        case "JOD":
            return "د.ا"
        case "OMR":
            return "ر.ع."
        case "BHD":
            return "د.ب"
        case "LBP":
            return "ل.ل"
        case "KHR":
            return "៛"
        case "MMK":
            return "K"
        case "LAK":
            return "₭"
        case "MNT":
            return "₮"
        case "NPR":
            return "₨"
        case "KZT":
            return "₸"
        case "UZS":
            return "so'm"
        case "GEL":
            return "₾"
        case "AMD":
            return "֏"
        case "AZN":
            return "₼"
        case "BYN":
            return "Br"
        case "MDL":
            return "L"
        case "TJS":
            return "ЅМ"
        case "TMT":
            return "T"
        case "KGS":
            return "с"
        case "AFN":
            return "؋"
        case "IRR":
            return "﷼"
        case "IQD":
            return "ع.د"
        case "YER":
            return "﷼"
        case "SYP":
            return "ل.س"
        case "LYD":
            return "ل.د"
        case "SDG":
            return "ج.س."
        case "ETB":
            return "Br"
        case "KES":
            return "KSh"
        case "UGX":
            return "USh"
        case "TZS":
            return "TSh"
        case "GHS":
            return "₵"
        case "XOF":
            return "CFA"
        case "XAF":
            return "FCFA"
        case "ZMW":
            return "ZK"
        case "MWK":
            return "MK"
        case "BWP":
            return "P"
        case "NAD":
            return "N$"
        case "MUR":
            return "₨"
        case "SCR":
            return "₨"
        case "MVR":
            return "Rf"
        case "BND":
            return "B$"
        case "KYD":
            return "CI$"
        case "BBD":
            return "Bds$"
        case "JMD":
            return "J$"
        case "TTD":
            return "TT$"
        case "GYD":
            return "G$"
        case "SRD":
            return "SRD"
        case "FJD":
            return "FJ$"
        case "WST":
            return "T"
        case "TOP":
            return "T$"
        case "VUV":
            return "VT"
        case "SBD":
            return "SI$"
        case "PGK":
            return "K"
        case "KID":
            return "$"
        case "TVD":
            return "$"
        case "NIO":
            return "C$"
        case "HNL":
            return "L"
        case "GTQ":
            return "Q"
        case "BZD":
            return "BZ$"
        case "SVC":
            return "₡"
        case "CRC":
            return "₡"
        case "PAB":
            return "B/."
        case "PYG":
            return "₲"
        case "UYU":
            return "$"
        case "BOB":
            return "Bs"
        case "PEN":
            return "S/"
        case "ECU":
            return "S/."
        case "VEF":
            return "Bs"
        default:
            return "$"
        }
    }
    
    func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = getCurrencySymbol()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(getCurrencySymbol())\(amount)"
    }
    
    func flagForCurrency(_ currency: String) -> String {
        switch currency {
        case "USD":
            return "🇺🇸"
        case "EUR":
            return "🇪🇺"
        case "GBP":
            return "🇬🇧"
        case "JPY":
            return "🇯🇵"
        case "CAD":
            return "🇨🇦"
        case "AUD":
            return "🇦🇺"
        case "CHF":
            return "🇨🇭"
        case "CNY":
            return "🇨🇳"
        case "SEK":
            return "🇸🇪"
        case "NZD":
            return "🇳🇿"
        case "MXN":
            return "🇲🇽"
        case "SGD":
            return "🇸🇬"
        case "HKD":
            return "🇭🇰"
        case "NOK":
            return "🇳🇴"
        case "KRW":
            return "🇰🇷"
        case "TRY":
            return "🇹🇷"
        case "RUB":
            return "🇷🇺"
        case "INR":
            return "🇮🇳"
        case "BRL":
            return "🇧🇷"
        case "ZAR":
            return "🇿🇦"
        case "ILS":
            return "🇮🇱"
        case "AED":
            return "🇦🇪"
        case "SAR":
            return "🇸🇦"
        case "PLN":
            return "🇵🇱"
        case "THB":
            return "🇹🇭"
        case "IDR":
            return "🇮🇩"
        case "CZK":
            return "🇨🇿"
        case "HUF":
            return "🇭🇺"
        case "CLP":
            return "🇨🇱"
        case "PHP":
            return "🇵🇭"
        case "MYR":
            return "🇲🇾"
        case "COP":
            return "🇨🇴"
        case "RON":
            return "🇷🇴"
        case "VND":
            return "🇻🇳"
        case "EGP":
            return "🇪🇬"
        case "UAH":
            return "🇺🇦"
        case "ARS":
            return "🇦🇷"
        case "QAR":
            return "🇶🇦"
        case "KWD":
            return "🇰🇼"
        case "BDT":
            return "🇧🇩"
        case "NGN":
            return "🇳🇬"
        case "MAD":
            return "🇲🇦"
        case "PKR":
            return "🇵🇰"
        case "DKK":
            return "🇩🇰"
        case "BGN":
            return "🇧🇬"
        case "HRK":
            return "🇭🇷"
        case "RSD":
            return "🇷🇸"
        case "ISK":
            return "🇮🇸"
        case "LKR":
            return "🇱🇰"
        case "TND":
            return "🇹🇳"
        case "JOD":
            return "🇯🇴"
        case "OMR":
            return "🇴🇲"
        case "BHD":
            return "🇧🇭"
        case "LBP":
            return "🇱🇧"
        case "KHR":
            return "🇰🇭"
        case "MMK":
            return "🇲🇲"
        case "LAK":
            return "🇱🇦"
        case "MNT":
            return "🇲🇳"
        case "NPR":
            return "🇳🇵"
        case "KZT":
            return "🇰🇿"
        case "UZS":
            return "🇺🇿"
        case "GEL":
            return "🇬🇪"
        case "AMD":
            return "🇦🇲"
        case "AZN":
            return "🇦🇿"
        case "BYN":
            return "🇧🇾"
        case "MDL":
            return "🇲🇩"
        case "TJS":
            return "🇹🇯"
        case "TMT":
            return "🇹🇲"
        case "KGS":
            return "🇰🇬"
        case "AFN":
            return "🇦🇫"
        case "IRR":
            return "🇮🇷"
        case "IQD":
            return "🇮🇶"
        case "YER":
            return "🇾🇪"
        case "SYP":
            return "🇸🇾"
        case "LYD":
            return "🇱🇾"
        case "SDG":
            return "🇸🇩"
        case "ETB":
            return "🇪🇹"
        case "KES":
            return "🇰🇪"
        case "UGX":
            return "🇺🇬"
        case "TZS":
            return "🇹🇿"
        case "GHS":
            return "🇬🇭"
        case "XOF":
            return "🇨🇮"
        case "XAF":
            return "🇨🇲"
        case "ZMW":
            return "🇿🇲"
        case "MWK":
            return "🇲🇼"
        case "BWP":
            return "🇧🇼"
        case "NAD":
            return "🇳🇦"
        case "MUR":
            return "🇲🇺"
        case "SCR":
            return "🇸🇨"
        case "MVR":
            return "🇲🇻"
        case "BND":
            return "🇧🇳"
        case "KYD":
            return "🇰🇾"
        case "BBD":
            return "🇧🇧"
        case "JMD":
            return "🇯🇲"
        case "TTD":
            return "🇹🇹"
        case "GYD":
            return "🇬🇾"
        case "SRD":
            return "🇸🇷"
        case "FJD":
            return "🇫🇯"
        case "WST":
            return "🇼🇸"
        case "TOP":
            return "🇹🇴"
        case "VUV":
            return "🇻🇺"
        case "SBD":
            return "🇸🇧"
        case "PGK":
            return "🇵🇬"
        case "KID":
            return "🇰🇮"
        case "TVD":
            return "🇹🇻"
        case "NIO":
            return "🇳🇮"
        case "HNL":
            return "🇭🇳"
        case "GTQ":
            return "🇬🇹"
        case "BZD":
            return "🇧🇿"
        case "SVC":
            return "🇸🇻"
        case "CRC":
            return "🇨🇷"
        case "PAB":
            return "🇵🇦"
        case "PYG":
            return "🇵🇾"
        case "UYU":
            return "🇺🇾"
        case "BOB":
            return "🇧🇴"
        case "PEN":
            return "🇵🇪"
        case "ECU":
            return "🇪🇨"
        case "VEF":
            return "🇻🇪"
        default:
            return "🇺🇸"
        }
    }
}
