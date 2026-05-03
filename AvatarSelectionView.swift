//
//  AvatarSelectionView.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 17/09/2025.
//

import SwiftUI

struct AvatarSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    let onAvatarSelected: (String) -> Void
    
    // Array of avatar image names
    private let avatarNames = [
        "avatar1", "avatar2", "avatar3", "avatar4", "avatar5",
        "avatar6", "avatar7", "avatar8", "avatar9", "avatar10"
    ]
    
    // Grid layout with 3 columns
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Choose Avatar")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Select an avatar for your profile")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Avatar Grid
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(avatarNames, id: \.self) { avatarName in
                            Button(action: {
                                onAvatarSelected(avatarName)
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(avatarName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                                    )
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

#Preview {
    AvatarSelectionView { avatarName in
        print("Selected avatar: \(avatarName)")
    }
}