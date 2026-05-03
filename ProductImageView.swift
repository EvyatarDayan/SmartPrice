//
//  ProductImageView.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 15/09/2025.
//

import SwiftUI

struct ProductImageView: View {
    let imageUrl: String?
    let imageData: Data?
    let placeholder: String
    let width: CGFloat
    let height: CGFloat
    
    @State private var downloadedImageData: Data?
    @State private var isLoading = false
    @State private var hasError = false
    
    init(imageUrl: String? = nil, imageData: Data? = nil, placeholder: String = "photo", width: CGFloat = 100, height: CGFloat = 100) {
        self.imageUrl = imageUrl
        self.imageData = imageData
        self.placeholder = placeholder
        self.width = width
        self.height = height
    }
    
    var body: some View {
        Group {
            // First priority: local imageData (from scanning)
            if let localImageData = imageData, let uiImage = UIImage(data: localImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .clipped()
                    .cornerRadius(8)
            }
            // Second priority: downloaded image from Firebase Storage
            else if let downloadedImageData = downloadedImageData, let uiImage = UIImage(data: downloadedImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .clipped()
                    .cornerRadius(8)
            }
            // Loading state
            else if isLoading {
                ProgressView()
                    .frame(width: width, height: height)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            // Error state or Default placeholder - show generic product image
            else {
                Image("GenericProduct")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .clipped()
                    .cornerRadius(8)
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: imageUrl) { _ in
            loadImage()
        }
    }
    
    private func loadImage() {
        // If we have local imageData, don't try to download
        if imageData != nil {
            downloadedImageData = nil
            isLoading = false
            hasError = false
            return
        }
        
        // If no imageUrl, show placeholder
        guard let imageUrl = imageUrl, !imageUrl.isEmpty else {
            downloadedImageData = nil
            isLoading = false
            hasError = false
            return
        }
        
        // Check if we already have the image cached
        if let cachedImage = FirebaseStorageManager.shared.getCachedImage(for: imageUrl),
           let imageData = cachedImage.jpegData(compressionQuality: 1.0) {
            downloadedImageData = imageData
            isLoading = false
            hasError = false
            return
        }
        
        isLoading = true
        hasError = false
        
        FirebaseStorageManager.shared.downloadAndCacheImage(from: imageUrl) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let data):
                    downloadedImageData = data
                    hasError = false
                case .failure(let error):
                    print("DEBUG: Error loading product image: \(error)")
                    downloadedImageData = nil
                    hasError = true
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            // Small size (no text)
            ProductImageView(imageUrl: nil, placeholder: "photo", width: 60, height: 60)
            
            // Medium size (with text)
            ProductImageView(imageUrl: nil, placeholder: "photo", width: 100, height: 100)
            
            // Large size (with text)
            ProductImageView(imageUrl: nil, placeholder: "photo", width: 150, height: 150)
        }
        
        HStack(spacing: 20) {
            // Error state
            ProductImageView(imageUrl: "invalid-url", placeholder: "photo", width: 100, height: 100)
            
            // Loading state simulation
            ProductImageView(imageUrl: "https://example.com/loading.jpg", placeholder: "photo", width: 100, height: 100)
        }
    }
    .padding()
}
