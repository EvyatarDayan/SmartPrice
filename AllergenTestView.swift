//
//  AllergenTestView.swift
//  SmartPrice
//
//  Created by AI Assistant on 10/10/2025.
//

import SwiftUI

struct AllergenTestView: View {
    @State private var commonAllergens: [String] = []
    @State private var apiAllergens: [String] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Open Food Facts Allergen Data")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                VStack(alignment: .leading, spacing: 16) {
                    // Common Allergens Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Common Allergens (25)")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 120), spacing: 8)
                        ], spacing: 8) {
                            ForEach(commonAllergens, id: \.self) { allergen in
                                Text(allergen.capitalized)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // API Allergens Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("API Allergens (\(apiAllergens.count))")
                                .font(.headline)
                                .foregroundColor(.green)
                            
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        
                        if apiAllergens.isEmpty && !isLoading {
                            Button("Load API Allergens") {
                                loadAPIAllergens()
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 120), spacing: 8)
                            ], spacing: 8) {
                                ForEach(apiAllergens, id: \.self) { allergen in
                                    Text(allergen.capitalized)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            loadCommonAllergens()
        }
    }
    
    private func loadCommonAllergens() {
        let apiService = ProductAPIService.shared
        commonAllergens = apiService.getCommonAllergens()
    }
    
    private func loadAPIAllergens() {
        isLoading = true
        Task {
            let apiService = ProductAPIService.shared
            let allergens = await apiService.getAllAvailableAllergens()
            
            await MainActor.run {
                apiAllergens = allergens
                isLoading = false
            }
        }
    }
}

#Preview {
    AllergenTestView()
}
