//
//  NutritionalInfoView.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 18/09/2025.
//

import SwiftUI

struct NutritionalInfoView: View {
    let nutritionalInfo: NutritionalInfo?
    let nutriscoreGrade: String?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Nutri-Score Header
                    if let grade = nutriscoreGrade, 
                       !grade.lowercased().contains("not-applicable") && 
                       !grade.lowercased().contains("unknown") && 
                       !grade.isEmpty {
                        
                        VStack(spacing: 12) {
                            Text("Nutri-Score")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            // Mini Nutri-Score display
                            HStack(spacing: 1) {
                                ForEach(["A", "B", "C", "D", "E"], id: \.self) { letter in
                                    let isSelected = letter.lowercased() == grade.lowercased()
                                    
                                    Text(letter)
                                        .font(.system(size: isSelected ? 16 : 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: isSelected ? 28 : 24, height: isSelected ? 28 : 24)
                                        .background(colorForGrade(letter))
                                        .cornerRadius(4)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color.appItemBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray5), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    
                    // Nutritional Information List
                    if let info = nutritionalInfo {
                        VStack(spacing: 0) {
                            // Energy (Calories)
                            if let energy = info.energyKcal {
                                nutritionalRow(
                                    icon: "flame.fill",
                                    iconColor: .orange,
                                    title: "Energy",
                                    value: "\(Int(energy)) kcal",
                                    subtitle: "Calories"
                                )
                                
                                Divider().padding(.leading, 76)
                            }
                            
                            // Fat
                            if let fat = info.fat {
                                nutritionalRow(
                                    icon: "drop.fill",
                                    iconColor: .yellow,
                                    title: "Fat",
                                    value: formatNutritionalValue(fat),
                                    subtitle: "Total fat content"
                                )
                                
                                Divider().padding(.leading, 76)
                            }
                            
                            // Saturated Fat
                            if let saturatedFat = info.saturatedFat {
                                nutritionalRow(
                                    icon: "drop.circle.fill",
                                    iconColor: .red,
                                    title: "Saturated Fat",
                                    value: formatNutritionalValue(saturatedFat),
                                    subtitle: "Saturated fat content"
                                )
                                
                                Divider().padding(.leading, 76)
                            }
                            
                            // Carbohydrates
                            if let carbs = info.carbohydrates {
                                nutritionalRow(
                                    icon: "leaf.fill",
                                    iconColor: .green,
                                    title: "Carbohydrates",
                                    value: formatNutritionalValue(carbs),
                                    subtitle: "Total carbohydrates"
                                )
                                
                                Divider().padding(.leading, 76)
                            }
                            
                            // Sugars
                            if let sugars = info.sugars {
                                nutritionalRow(
                                    icon: "cube.fill",
                                    iconColor: .pink,
                                    title: "Sugars",
                                    value: formatNutritionalValue(sugars),
                                    subtitle: "Total sugars"
                                )
                                
                                Divider().padding(.leading, 76)
                            }
                            
                            // Fiber
                            if let fiber = info.fiber {
                                nutritionalRow(
                                    icon: "leaf.arrow.circlepath",
                                    iconColor: .brown,
                                    title: "Fiber",
                                    value: formatNutritionalValue(fiber),
                                    subtitle: "Dietary fiber"
                                )
                                
                                Divider().padding(.leading, 76)
                            }
                            
                            // Proteins
                            if let proteins = info.proteins {
                                nutritionalRow(
                                    icon: "dumbbell.fill",
                                    iconColor: .blue,
                                    title: "Proteins",
                                    value: formatNutritionalValue(proteins),
                                    subtitle: "Protein content"
                                )
                                
                                Divider().padding(.leading, 76)
                            }
                            
                            // Salt
                            if let salt = info.salt {
                                nutritionalRow(
                                    icon: "circle.dotted",
                                    iconColor: .gray,
                                    title: "Salt",
                                    value: formatNutritionalValue(salt),
                                    subtitle: "Sodium content"
                                )
                                
                                // Don't add divider for last item
                                if info.novaGroup != nil || info.nutritionScore != nil {
                                    Divider().padding(.leading, 76)
                                }
                            }
                            
                            // NOVA Group
                            if let nova = info.novaGroup {
                                nutritionalRow(
                                    icon: "gearshape.fill",
                                    iconColor: .purple,
                                    title: "NOVA Group",
                                    value: "Group \(nova)",
                                    subtitle: novaGroupDescription(nova)
                                )
                                
                                if info.nutritionScore != nil {
                                    Divider().padding(.leading, 76)
                                }
                            }
                            
                            // Nutrition Score
                            if let score = info.nutritionScore {
                                nutritionalRow(
                                    icon: "chart.bar.fill",
                                    iconColor: .indigo,
                                    title: "Nutrition Score",
                                    value: "\(score)",
                                    subtitle: "Overall nutritional quality"
                                )
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
                    } else {
                        // No nutritional data available
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)
                            
                            Text("No Nutritional Data")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text("Nutritional information is not available for this product.")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 40)
                        .background(Color.appItemBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray5), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color.appBackground)
            .navigationTitle("Nutrition Facts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    @ViewBuilder
    private func nutritionalRow(icon: String, iconColor: Color, title: String, value: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.1))
                .cornerRadius(8)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(value)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.appItemBackground)
    }
    
    private func colorForGrade(_ letter: String) -> Color {
        switch letter {
        case "A": 
            return Color(red: 0x12/255.0, green: 0x85/255.0, blue: 0x48/255.0) // #128548 - Dark Green
        case "B": 
            return Color(red: 0x70/255.0, green: 0xc1/255.0, blue: 0x2d/255.0) // #70c12d - Light Green
        case "C": 
            return Color(red: 0xf2/255.0, green: 0xc0/255.0, blue: 0x0a/255.0) // #f2c00a - Golden Yellow
        case "D": 
            return Color(red: 0xed/255.0, green: 0x6e/255.0, blue: 0x16/255.0) // #ed6e16 - Orange
        case "E": 
            return Color(red: 0xe7/255.0, green: 0x31/255.0, blue: 0x1f/255.0) // #e7311f - Red
        default: 
            return Color.gray.opacity(0.25)
        }
    }
    
    private func formatNutritionalValue(_ value: Double) -> String {
        if value < 1.0 {
            return String(format: "%.1f g", value)
        } else {
            return String(format: "%.0f g", value)
        }
    }
    
    private func novaGroupDescription(_ group: Int) -> String {
        switch group {
        case 1:
            return "Unprocessed or minimally processed"
        case 2:
            return "Processed culinary ingredients"
        case 3:
            return "Processed foods"
        case 4:
            return "Ultra-processed foods"
        default:
            return "Processing level classification"
        }
    }
}

#Preview {
    NutritionalInfoView(
        nutritionalInfo: NutritionalInfo(
            energyKcal: 450,
            fat: 25.0,
            saturatedFat: 12.0,
            sugars: 8.5,
            salt: 1.2,
            proteins: 6.0,
            carbohydrates: 52.0,
            fiber: 3.5,
            nutritionScore: 15,
            novaGroup: 4
        ),
        nutriscoreGrade: "C"
    )
}

