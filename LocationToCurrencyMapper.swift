//
//  LocationToCurrencyMapper.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 15/09/2025.
//

import Foundation

class LocationToCurrencyMapper {
    static let shared = LocationToCurrencyMapper()
    
    private init() {}
    
    // MARK: - Country to Currency Mapping
    
    private let countryToCurrency: [String: String] = [
        // North America
        "United States": "USD",
        "USA": "USD",
        "US": "USD",
        "Canada": "CAD",
        "Mexico": "MXN",
        
        // Europe
        "Germany": "EUR",
        "France": "EUR",
        "Italy": "EUR",
        "Spain": "EUR",
        "Netherlands": "EUR",
        "Belgium": "EUR",
        "Austria": "EUR",
        "Portugal": "EUR",
        "Ireland": "EUR",
        "Finland": "EUR",
        "Greece": "EUR",
        "Luxembourg": "EUR",
        "Slovenia": "EUR",
        "Cyprus": "EUR",
        "Malta": "EUR",
        "Slovakia": "EUR",
        "Estonia": "EUR",
        "Latvia": "EUR",
        "Lithuania": "EUR",
        "United Kingdom": "GBP",
        "UK": "GBP",
        "Great Britain": "GBP",
        "Switzerland": "CHF",
        "Sweden": "SEK",
        "Norway": "NOK",
        "Denmark": "DKK",
        "Poland": "PLN",
        "Czech Republic": "CZK",
        "Hungary": "HUF",
        "Romania": "RON",
        "Bulgaria": "BGN",
        "Croatia": "HRK",
        "Russia": "RUB",
        "Turkey": "TRY",
        
        // Asia
        "Japan": "JPY",
        "China": "CNY",
        "South Korea": "KRW",
        "India": "INR",
        "Singapore": "SGD",
        "Hong Kong": "HKD",
        "Thailand": "THB",
        "Malaysia": "MYR",
        "Indonesia": "IDR",
        "Philippines": "PHP",
        "Vietnam": "VND",
        "Taiwan": "TWD",
        "Israel": "ILS",
        "Saudi Arabia": "SAR",
        "United Arab Emirates": "AED",
        "UAE": "AED",
        "Kuwait": "KWD",
        "Qatar": "QAR",
        "Bahrain": "BHD",
        "Oman": "OMR",
        "Jordan": "JOD",
        "Lebanon": "LBP",
        "Egypt": "EGP",
        
        // Oceania
        "Australia": "AUD",
        "New Zealand": "NZD",
        
        // South America
        "Brazil": "BRL",
        "Argentina": "ARS",
        "Chile": "CLP",
        "Colombia": "COP",
        "Peru": "PEN",
        "Uruguay": "UYU",
        "Paraguay": "PYG",
        "Bolivia": "BOB",
        "Ecuador": "USD", // Ecuador uses USD
        "Venezuela": "VES",
        
        // Africa
        "South Africa": "ZAR",
        "Nigeria": "NGN",
        "Kenya": "KES",
        "Ghana": "GHS",
        "Morocco": "MAD",
        "Tunisia": "TND",
        "Algeria": "DZD",
        "Ethiopia": "ETB",
        "Uganda": "UGX",
        "Tanzania": "TZS",
        "Zimbabwe": "ZWL",
        
        // Other
        "Iceland": "ISK",
        "Ukraine": "UAH",
        "Belarus": "BYN",
        "Kazakhstan": "KZT",
        "Uzbekistan": "UZS",
        "Kyrgyzstan": "KGS",
        "Tajikistan": "TJS",
        "Turkmenistan": "TMT",
        "Afghanistan": "AFN",
        "Pakistan": "PKR",
        "Bangladesh": "BDT",
        "Sri Lanka": "LKR",
        "Nepal": "NPR",
        "Bhutan": "BTN",
        "Maldives": "MVR",
        "Myanmar": "MMK",
        "Cambodia": "KHR",
        "Laos": "LAK",
        "Mongolia": "MNT",
        "North Korea": "KPW"
    ]
    
    // MARK: - City to Currency Mapping (for special cases)
    
    private let cityToCurrency: [String: String] = [
        // European cities that might not be detected as countries
        "Stockholm": "SEK",
        "Gothenburg": "SEK",
        "Malmö": "SEK",
        "Oslo": "NOK",
        "Bergen": "NOK",
        "Trondheim": "NOK",
        "Copenhagen": "DKK",
        "Aarhus": "DKK",
        "Warsaw": "PLN",
        "Krakow": "PLN",
        "Prague": "CZK",
        "Brno": "CZK",
        "Budapest": "HUF",
        "Debrecen": "HUF",
        "Bucharest": "RON",
        "Cluj-Napoca": "RON",
        "Sofia": "BGN",
        "Plovdiv": "BGN",
        "Zagreb": "HRK",
        "Split": "HRK",
        "Moscow": "RUB",
        "Saint Petersburg": "RUB",
        "Istanbul": "TRY",
        "Ankara": "TRY",
        "Zurich": "CHF",
        "Geneva": "CHF",
        "Basel": "CHF",
        "Bern": "CHF",
        "London": "GBP",
        "Manchester": "GBP",
        "Birmingham": "GBP",
        "Edinburgh": "GBP",
        "Dublin": "EUR",
        "Cork": "EUR",
        "Reykjavik": "ISK",
        "Akureyri": "ISK",
        "Kiev": "UAH",
        "Kharkiv": "UAH",
        "Minsk": "BYN",
        "Gomel": "BYN",
        "Almaty": "KZT",
        "Nur-Sultan": "KZT",
        "Tashkent": "UZS",
        "Samarkand": "UZS",
        "Bishkek": "KGS",
        "Osh": "KGS",
        "Dushanbe": "TJS",
        "Khujand": "TJS",
        "Ashgabat": "TMT",
        "Turkmenabat": "TMT",
        "Kabul": "AFN",
        "Herat": "AFN",
        "Islamabad": "PKR",
        "Karachi": "PKR",
        "Lahore": "PKR",
        "Dhaka": "BDT",
        "Chittagong": "BDT",
        "Colombo": "LKR",
        "Kandy": "LKR",
        "Kathmandu": "NPR",
        "Pokhara": "NPR",
        "Thimphu": "BTN",
        "Phuntsholing": "BTN",
        "Malé": "MVR",
        "Addu City": "MVR",
        "Yangon": "MMK",
        "Mandalay": "MMK",
        "Phnom Penh": "KHR",
        "Siem Reap": "KHR",
        "Vientiane": "LAK",
        "Luang Prabang": "LAK",
        "Ulaanbaatar": "MNT",
        "Darkhan": "MNT",
        "Pyongyang": "KPW",
        "Hamhung": "KPW"
    ]
    
    // MARK: - Public Methods
    
    func getCurrencyForLocation(city: String?, country: String?) -> String? {
        // First try to get currency by city (for special cases)
        if let city = city, let currency = cityToCurrency[city] {
            print("DEBUG: Found currency for city '\(city)': \(currency)")
            return currency
        }
        
        // Then try to get currency by country
        if let country = country, let currency = countryToCurrency[country] {
            print("DEBUG: Found currency for country '\(country)': \(currency)")
            return currency
        }
        
        // Try case-insensitive matching
        if let city = city {
            for (cityKey, currency) in cityToCurrency {
                if city.lowercased() == cityKey.lowercased() {
                    print("DEBUG: Found currency for city '\(city)' (case-insensitive): \(currency)")
                    return currency
                }
            }
        }
        
        if let country = country {
            for (countryKey, currency) in countryToCurrency {
                if country.lowercased() == countryKey.lowercased() {
                    print("DEBUG: Found currency for country '\(country)' (case-insensitive): \(currency)")
                    return currency
                }
            }
        }
        
        print("DEBUG: No currency found for city: '\(city ?? "nil")', country: '\(country ?? "nil")'")
        return nil
    }
    
    func getAllSupportedCountries() -> [String] {
        return Array(countryToCurrency.keys).sorted()
    }
    
    func getAllSupportedCities() -> [String] {
        return Array(cityToCurrency.keys).sorted()
    }
}

