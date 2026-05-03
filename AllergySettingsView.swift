//
//  AllergySettingsView.swift
//  SmartPrice
//
//  Created by AI Assistant on 10/10/2025.
//

import SwiftUI

struct AllergySettingsView: View {
    @StateObject private var allergyManager = AllergyManager.shared
    @State private var newAllergy = ""
    @State private var newIngredient = ""
    @State private var showingAddAllergy = false
    @State private var showingAddIngredient = false
    @State private var selectedAllergen = ""
    @State private var tempSelectedAllergens: Set<String> = []
    
    private let commonAllergens = [
        "milk", "eggs", "fish", "crustaceans", "tree-nuts", "peanuts", 
        "wheat", "soybeans", "sesame", "mustard", "celery", "lupin", 
        "molluscs", "sulphites", "gluten", "nuts", "almonds", "walnuts", 
        "hazelnuts", "pistachios", "cashews", "pecans", "brazil-nuts", 
        "macadamia-nuts", "pine-nuts"
    ].sorted()
    
    var body: some View {
        VStack(spacing: 0) {
            // Allergies Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Allergies")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        showingAddAllergy = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                if allergyManager.userAllergies.isEmpty {
                    Text("No allergies set")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 100), spacing: 8)
                    ], spacing: 8) {
                        ForEach(Array(allergyManager.userAllergies.sorted()), id: \.self) { allergy in
                            AllergyChip(
                                text: allergy.capitalized,
                                onRemove: {
                                    allergyManager.removeAllergy(allergy)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
            }
            
            Divider()
                .padding(.horizontal, 20)
            
            // Ingredients Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Ingredients to Avoid")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        showingAddIngredient = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                if allergyManager.userIngredients.isEmpty {
                    Text("No ingredients set")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 100), spacing: 8)
                    ], spacing: 8) {
                        ForEach(Array(allergyManager.userIngredients.sorted()), id: \.self) { ingredient in
                            AllergyChip(
                                text: ingredient.capitalized,
                                onRemove: {
                                    allergyManager.removeIngredient(ingredient)
                                }
                            )
                        }
                    }
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
        .sheet(isPresented: $showingAddAllergy) {
            NavigationView {
                VStack(spacing: 20) {
                    Text("Select allergies to add")
                        .font(.headline)
                        .padding(.top)
                    
                    List {
                        ForEach(commonAllergens, id: \.self) { allergen in
                            Button(action: {
                                if tempSelectedAllergens.contains(allergen) {
                                    tempSelectedAllergens.remove(allergen)
                                } else {
                                    tempSelectedAllergens.insert(allergen)
                                }
                            }) {
                                HStack {
                                    Text(allergen.capitalized)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if tempSelectedAllergens.contains(allergen) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Add Allergies")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    leading: Button("Cancel") {
                        tempSelectedAllergens.removeAll()
                        showingAddAllergy = false
                    },
                    trailing: Button("Done") {
                        // Update allergies: remove deselected ones and add new ones
                        let currentAllergies = Set(allergyManager.userAllergies)
                        let newAllergies = tempSelectedAllergens
                        
                        // Remove allergies that are no longer selected
                        let toRemove = currentAllergies.subtracting(newAllergies)
                        for allergen in toRemove {
                            allergyManager.removeAllergy(allergen)
                        }
                        
                        // Add new allergies that weren't previously selected
                        let toAdd = newAllergies.subtracting(currentAllergies)
                        for allergen in toAdd {
                            allergyManager.addAllergy(allergen)
                        }
                        
                        tempSelectedAllergens.removeAll()
                        showingAddAllergy = false
                    }
                    .disabled(tempSelectedAllergens.isEmpty)
                )
                .onAppear {
                    // Initialize with currently selected allergies
                    tempSelectedAllergens = allergyManager.userAllergies
                }
            }
        }
        .alert("Add Ingredient", isPresented: $showingAddIngredient) {
            TextField("Ingredient name", text: $newIngredient)
            Button("Add") {
                if !newIngredient.isEmpty {
                    allergyManager.addIngredient(newIngredient)
                    newIngredient = ""
                }
            }
            Button("Cancel", role: .cancel) {
                newIngredient = ""
            }
        } message: {
            Text("Enter an ingredient to be alerted about when scanning products.")
        }
    }
}

struct AllergyChip: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    AllergySettingsView()
}
