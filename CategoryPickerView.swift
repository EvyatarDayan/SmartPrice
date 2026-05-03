//
//  CategoryPickerView.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 15/09/2025.
//

import SwiftUI

struct CategoryPickerView: View {
    @Binding var selectedCategory: String
    @Environment(\.presentationMode) var presentationMode
    
    private let categories = ["Produce", "Dairy", "Meat", "Bakery", "Beverages", "Snacks", "Household", "Electronics", "Other"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(categories, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack(spacing: 16) {
                                // Category icon
                                Image(systemName: iconForCategory(category))
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.blue)
                                    .frame(width: 40, height: 40)
                                
                                // Category name
                                Text(category)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                // Selection indicator
                                if selectedCategory == category {
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
                        
                        if category != categories.last {
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
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Produce":
            return "leaf.fill"
        case "Dairy":
            return "drop.fill"
        case "Meat":
            return "fish.fill"
        case "Bakery":
            return "birthday.cake.fill"
        case "Beverages":
            return "cup.and.saucer.fill"
        case "Snacks":
            return "bag.fill"
        case "Household":
            return "house.fill"
        case "Electronics":
            return "laptopcomputer"
        case "Other":
            return "questionmark.circle.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
}

#Preview {
    CategoryPickerView(selectedCategory: .constant("Produce"))
}
