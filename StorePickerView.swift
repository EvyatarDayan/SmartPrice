//
//  StorePickerView.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 10/09/2025.
//

import SwiftUI

struct StorePickerView: View {
    @Binding var selectedStore: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // None option
                    Button(action: {
                        selectedStore = ""
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 16) {
                            // None icon
                            ZStack {
                                Image(systemName: "cart")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                Image(systemName: "line.diagonal")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.red)
                            }
                            .frame(width: 40, height: 40)
                            
                            // None text
                            Text("None")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            // Selection indicator
                            if selectedStore.isEmpty {
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
                    
                    Divider()
                        .padding(.leading, 76)
                    
                    ForEach(Store.knownStores) { store in
                        Button(action: {
                            selectedStore = store.name
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack(spacing: 16) {
                                // Store Logo
                                Image(store.logoName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 40, height: 40)
                                    .cornerRadius(8)
                                
                                // Store Name
                                Text(store.name)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                // Selection indicator
                                if selectedStore == store.name {
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
                        
                        if store.id != Store.knownStores.last?.id {
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
            .navigationTitle("Select Store")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    StorePickerView(selectedStore: .constant("ICA"))
}
