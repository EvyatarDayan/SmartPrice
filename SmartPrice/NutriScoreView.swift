//
//  NutriScoreView.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 18/09/2025.
//

import SwiftUI

struct NutriScoreView: View {
    let grade: String?
    let nutritionalInfo: NutritionalInfo?
    @State private var showingNutritionalInfo = false
    
    // Convenience initializer for backward compatibility
    init(grade: String?) {
        self.grade = grade
        self.nutritionalInfo = nil
    }
    
    // Full initializer with nutritional info
    init(grade: String?, nutritionalInfo: NutritionalInfo?) {
        self.grade = grade
        self.nutritionalInfo = nutritionalInfo
    }
    
    var body: some View {
        Button(action: {
            showingNutritionalInfo = true
        }) {
            HStack(spacing: 8) {
                Text("NUTRI-SCORE")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                
                Spacer()
                
                // A-E Grade visualization (like the provided image)
                HStack(spacing: 1) {
                    ForEach(["A", "B", "C", "D", "E"], id: \.self) { letter in
                        let isSelected = letter.lowercased() == grade?.lowercased()
                        let hasValidGrade = grade != nil && 
                                          !grade!.lowercased().contains("not-applicable") && 
                                          !grade!.lowercased().contains("unknown") && 
                                          !grade!.isEmpty
                        let shouldHighlight = isSelected && hasValidGrade
                        
                        Text(letter)
                            .font(.system(size: shouldHighlight ? 18 : 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: shouldHighlight ? 32 : 28, height: shouldHighlight ? 32 : 28)
                            .background(colorForGrade(letter, currentGrade: grade))
                            .cornerRadius(4)
                            .scaleEffect(shouldHighlight ? 1.0 : 0.95)
                            .shadow(color: shouldHighlight ? Color.black.opacity(0.3) : Color.clear, radius: shouldHighlight ? 3 : 0, x: 0, y: 1)
                            .animation(.easeInOut(duration: 0.2), value: shouldHighlight)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            print("DEBUG: NutriScoreView displaying grade: '\(grade ?? "nil")'")
        }
        .sheet(isPresented: $showingNutritionalInfo) {
            NutritionalInfoView(nutritionalInfo: nutritionalInfo, nutriscoreGrade: grade)
        }
    }
    
    private func colorForGrade(_ letter: String, currentGrade: String?) -> Color {
        // If grade is not-applicable or unknown, show all letters in gray
        if let grade = currentGrade?.lowercased(), 
           grade == "not-applicable" || grade == "unknown" || grade.isEmpty {
            return Color.gray.opacity(0.25)
        }
        
        // Otherwise show official colors for all letters
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
}

#Preview {
    VStack(spacing: 20) {
        NutriScoreView(grade: "A", nutritionalInfo: NutritionalInfo(
            energyKcal: 350, fat: 15.0, saturatedFat: 8.0, sugars: 12.0, salt: 0.8, 
            proteins: 8.0, carbohydrates: 45.0, fiber: 5.0, nutritionScore: 10, novaGroup: 3
        ))
        NutriScoreView(grade: "B")
        NutriScoreView(grade: "C")
        NutriScoreView(grade: "D")
        NutriScoreView(grade: "E")
        NutriScoreView(grade: "not-applicable")
        NutriScoreView(grade: "unknown")
        NutriScoreView(grade: nil)
    }
    .padding()
}
