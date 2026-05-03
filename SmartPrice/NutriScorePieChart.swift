//
//  NutriScorePieChart.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 18/09/2025.
//

import SwiftUI

struct NutriScorePieChart: View {
    let breakdown: NutriScoreBreakdown
    
    private struct GradeData {
        let grade: String
        let count: Int
        let color: Color
        let angle: Double
    }
    
    private var gradeData: [GradeData] {
        var data: [GradeData] = []
        let totalItems = breakdown.totalItems
        
        if breakdown.gradeA > 0 {
            data.append(GradeData(
                grade: "A",
                count: breakdown.gradeA,
                color: Color(red: 0x12/255.0, green: 0x85/255.0, blue: 0x48/255.0),
                angle: Double(breakdown.gradeA) / Double(totalItems) * 360
            ))
        }
        
        if breakdown.gradeB > 0 {
            data.append(GradeData(
                grade: "B",
                count: breakdown.gradeB,
                color: Color(red: 0x70/255.0, green: 0xc1/255.0, blue: 0x2d/255.0),
                angle: Double(breakdown.gradeB) / Double(totalItems) * 360
            ))
        }
        
        if breakdown.gradeC > 0 {
            data.append(GradeData(
                grade: "C",
                count: breakdown.gradeC,
                color: Color(red: 0xf2/255.0, green: 0xc0/255.0, blue: 0x0a/255.0),
                angle: Double(breakdown.gradeC) / Double(totalItems) * 360
            ))
        }
        
        if breakdown.gradeD > 0 {
            data.append(GradeData(
                grade: "D",
                count: breakdown.gradeD,
                color: Color(red: 0xed/255.0, green: 0x6e/255.0, blue: 0x16/255.0),
                angle: Double(breakdown.gradeD) / Double(totalItems) * 360
            ))
        }
        
        if breakdown.gradeE > 0 {
            data.append(GradeData(
                grade: "E",
                count: breakdown.gradeE,
                color: Color(red: 0xe7/255.0, green: 0x31/255.0, blue: 0x1f/255.0),
                angle: Double(breakdown.gradeE) / Double(totalItems) * 360
            ))
        }
        
        if breakdown.unknown > 0 {
            data.append(GradeData(
                grade: "?",
                count: breakdown.unknown,
                color: Color.gray,
                angle: Double(breakdown.unknown) / Double(totalItems) * 360
            ))
        }
        
        return data
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // Pie Chart
            ZStack {
                ForEach(Array(gradeData.enumerated()), id: \.offset) { index, grade in
                    let startAngle = gradeData.prefix(index).reduce(0) { $0 + $1.angle }
                    
                    PieSlice(
                        startAngle: .degrees(startAngle - 90), // Start from top
                        endAngle: .degrees(startAngle + grade.angle - 90),
                        color: grade.color
                    )
                }
                
                // Center circle for donut effect
                Circle()
                    .fill(Color.appBackground)
                    .frame(width: 100, height: 100)
                
                // Total items in center
                VStack(spacing: 4) {
                    Text("\(breakdown.totalItems)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("items")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 200, height: 200)
            
            // Legend
            VStack(alignment: .leading, spacing: 8) {
                ForEach(gradeData, id: \.grade) { grade in
                    HStack(spacing: 8) {
                        // Color indicator
                        RoundedRectangle(cornerRadius: 3)
                            .fill(grade.color)
                            .frame(width: 20, height: 20)
                        
                        // Grade letter
                        Text(grade.grade)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                        
                        // Count
                        Text("\(grade.count)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct PieSlice: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2
                
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false
                )
                path.closeSubpath()
            }
            .fill(color)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        NutriScorePieChart(breakdown: NutriScoreBreakdown(
            gradeA: 2,
            gradeB: 1,
            gradeC: 3,
            gradeD: 2,
            gradeE: 0,
            unknown: 0,
            totalItems: 8
        ))
        
        NutriScorePieChart(breakdown: NutriScoreBreakdown(
            gradeA: 1,
            gradeB: 2,
            gradeC: 1,
            gradeD: 1,
            gradeE: 2,
            unknown: 1,
            totalItems: 8
        ))
    }
    .padding()
}
